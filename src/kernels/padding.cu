#include "kernels.h"
#include <thrust/pair.h>
#include <stdio.h>

/*
 * Reflection padding is from https://github.com/pytorch/pytorch/blob/master/aten/src/ATen/native/cuda/ReflectionPad.cu
 */
__device__
inline thrust::pair<int32_t,int32_t> get_index_mapping2d(
        int32_t input_dim_x,int32_t input_dim_y,int32_t output_dim_x,
        int32_t output_dim_y,int32_t pad_l,int32_t pad_t,int32_t output_xy,
        int32_t y_shift,int32_t z_shift,int32_t n_plane){
    auto input_offset = ((blockIdx.y + y_shift) + (blockIdx.z + z_shift)*n_plane)*input_dim_x*input_dim_y;
    auto output_offset = ((blockIdx.y + y_shift) + (blockIdx.z + z_shift)*n_plane)*output_dim_x*output_dim_y;
    auto output_x = output_xy % output_dim_x;
    auto output_y = output_xy/output_dim_x;

    auto i_start_x = ::max(int32_t(0),-pad_l);
    auto i_start_y = ::max(int32_t(0),-pad_t);
    auto o_start_x = ::max(int32_t(0),pad_l);
    auto o_start_y = ::max(int32_t(0),pad_t);

    auto input_x = ::abs(output_x - pad_l) - ::abs(output_x - (input_dim_x + pad_l -1)) -output_x + 2*pad_l + input_dim_x -1 -o_start_x + i_start_x;
    auto input_y = ::abs(output_y - pad_t) - ::abs(output_y - (input_dim_y + pad_t -1)) -output_y + 2*pad_t + input_dim_y -1 -o_start_y + i_start_y;

    return thrust::make_pair<int32_t,int32_t>(input_offset + input_y*input_dim_x + input_x,output_offset + output_y*output_dim_x+output_x);
}

__global__
void reflection_pad2d_out_kernel(
        float* input,float* output,int32_t input_dim_x,
        int32_t input_dim_y,int32_t pad_t,int32_t pad_b,int32_t pad_l,
        int32_t pad_r,int32_t y_shift,int32_t z_shift,int32_t n_plane){
    auto output_xy = threadIdx.x + blockIdx.x * blockDim.x;
    auto output_dim_x = input_dim_x + pad_l + pad_r;
    auto output_dim_y = input_dim_y + pad_t + pad_b;

    if(output_xy < output_dim_x*output_dim_y){
        auto index_pair = get_index_mapping2d(input_dim_x,input_dim_y,output_dim_x,output_dim_y,pad_l,pad_t,output_xy,y_shift,z_shift,n_plane);
        output[index_pair.second] = input[index_pair.first];
    }
}

int32_t ceilDiv(int32_t a,int32_t b){
    return (a+b-1)/b;
}


void reflection_pad2d_out_forward(int32_t pad_h,int32_t pad_w,float *srcData,float *dstData,int32_t input_h,int32_t input_w,int32_t plane_dim,int32_t n_batch,cudaStream_t cudaStream){
    int32_t pad_l = pad_w;
    int32_t pad_r = pad_w;
    int32_t pad_t = pad_h;
    int32_t pad_b = pad_w;
    int32_t output_h = input_h + pad_t + pad_b;
    int32_t output_w = input_w + pad_l + pad_r;
    int32_t size_y = plane_dim;
    int32_t size_z = n_batch;
    int32_t output_plane_size = output_h*output_w;
    dim3 block_size(output_plane_size>256 ?256:output_plane_size);
    for(int32_t block_y=0;block_y<size_y;block_y += 65535){
        int32_t block_y_size = std::min(size_y - block_y,static_cast<int32_t>(65535));
        for(int32_t block_z=0;block_z<size_z;block_z += 65535){
            int32_t block_z_size = std::min(size_z -block_z,static_cast<int32_t>(65535));

            dim3 grid_size(ceilDiv(output_plane_size,static_cast<int32_t>(256)),block_y_size,block_z_size);
            reflection_pad2d_out_kernel<<<grid_size,block_size,0,cudaStream>>>(srcData,dstData,input_w,input_h,pad_t,pad_b,pad_l,pad_r,block_y,block_z,plane_dim);
        }
    }

}

/*
 * constant padding is inspired from https://github.com/apache/incubator-mxnet/blob/master/src/operator/pad.cu
 */

__global__
void constant_pad2d_kernel(dnnType *srcData,dnnType *dstData,const int32_t padT,const int32_t padL,float constant,int32_t n,int32_t c,int32_t i_h,int32_t i_w,int32_t o_h,int32_t o_w){
    int outputPointId = threadIdx.x + blockIdx.x * blockDim.x;
    if(outputPointId >= o_h*o_w){
        return ;
    }

    int Ny = i_h;
    int Nx = i_w;

    int plane =   blockIdx.y;
    int batch = blockIdx.z;
    int outputPointX = outputPointId % o_w;
    int outputPointY = outputPointId / o_w;
    int checkT       = max(0, outputPointY - padT + 1);
    int checkB       = max(0, padT + Ny - outputPointY);
    int checkL       = max(0, outputPointX - padL + 1);
    int checkR       = max(0, padL + Nx - outputPointX);
    int inputPointX  = min(max(outputPointX - padL, 0), Nx - 1);
    int inputPointY  = min(max(outputPointY - padT, 0), Ny - 1);
    int need_pad     = !(checkT * checkB * checkL * checkR);
    float value_to_copy = srcData[batch*c*i_h*i_w + plane*i_h*i_w + inputPointY*i_w + inputPointX];
    dstData[batch*c*o_w*o_h + plane*o_h*o_w + outputPointY*o_w + outputPointX] = value_to_copy * (!need_pad) + need_pad*constant;

}

void constant_pad2d_forward(dnnType *srcData,dnnType *dstData,int32_t input_h,int32_t input_w,int32_t output_h,
                            int32_t output_w,int32_t c,int32_t n,int32_t padT,int32_t padL,dnnType constant,cudaStream_t cudaStream){
    int32_t output_plane_size = output_h*output_w;
    dim3 block_size(output_plane_size>256 ?256:output_plane_size);
    dim3 grid_size(ceilDiv(output_plane_size,static_cast<int32_t>(256)),c,n);
    constant_pad2d_kernel<<<grid_size,block_size,0,cudaStream>>>(srcData,dstData,padT,padL,constant,n,c,input_h,input_w,output_h,output_w);

}

