#include<iostream>
#include<vector>
#include "tkdnn.h"
#include "test.h"
#include "DarknetParser.h"

int main() {
    std::string bin_path  = "yolo3tiny_512";
    std::vector<std::string> input_bins = { 
        bin_path + "/layers/input.bin"
    };
    std::vector<std::string> output_bins = {
        bin_path + "/debug/layer16_out.bin",
        bin_path + "/debug/layer23_out.bin",
    };
    std::string wgs_path  = bin_path + "/layers";
    std::string cfg_path  = std::string(TKDNN_PATH) + "/tests/darknet/cfg/yolo3tiny_512.cfg";
    std::string name_path = std::string(TKDNN_PATH) + "/tests/darknet/names/coco.names";
    downloadWeightsifDoNotExist(input_bins[0], bin_path, "https://cloud.hipert.unimore.it/s/8Zt6bHwHADqP4JC/download");

    // parse darknet network
    tk::dnn::Network *net = tk::dnn::darknetParser(cfg_path, wgs_path, name_path);
    net->print();

//     for(int i=0; i<net->num_layers; i++) {
//         if(net->layers[i]->getLayerType() == tk::dnn::LAYER_CONV2D) {
//             tk::dnn::Conv2d *c = (tk::dnn::Conv2d*) net->layers[i];
//             c->releaseDevice();
//             c->releaseHost(true, false);
//         }
//         if(net->layers[i]->dstData != nullptr) {
//             cudaFree(net->layers[i]->dstData);
//             net->layers[i]->dstData = nullptr;
//         }
//    }


    //convert network to tensorRT
    tk::dnn::NetworkRT *netRT = new tk::dnn::NetworkRT(net, net->getNetworkRTName(bin_path.c_str()));
    
    int ret = testInference(input_bins, output_bins, net, netRT);
    net->releaseLayers();
    delete net;
    netRT->destroy();
    delete netRT;
    return ret;
}
