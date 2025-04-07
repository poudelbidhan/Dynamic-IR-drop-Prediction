import os
import argparse
import numpy as np
import torch
from IR_drop_model import IRdropModel
import cv2
import matplotlib.pyplot as plt
import pandas as pd
import torch.nn.functional as F 

class IRDropPrediction():
    def __init__(self, datapath, features, model_path, device, ground_truth_path=None):
        super(IRDropPrediction, self).__init__()
        self.datapath = datapath
        self.FeaturePathList = features
        self.feature = self.data_process(self.FeaturePathList).unsqueeze(0).to(device)
        self.model = IRdropModel(in_channel=26, device=device).to(device)
        checkpoint = torch.load(model_path)
        self.model.load_state_dict(checkpoint)
        self.model.eval()
        self.device = device
        self.ground_truth = None

        if ground_truth_path:
            self.ground_truth = self.load_ground_truth(ground_truth_path)

    def resize_cv2(self, input):
        output = cv2.resize(input, (256, 256), interpolation=cv2.INTER_AREA)
        return output

    def std(self, input):
        if input.max() == 0:
            return input
        else:
            result = (input - input.min()) / (input.max() - input.min())
            return result

    def data_process(self, FeaturePathList):
        features = []
        for feature_name in FeaturePathList:
            name = os.listdir(os.path.join(self.datapath, feature_name))[0]
            feature = np.load(os.path.join(self.datapath, feature_name, name))
            if feature_name == "power_t":
                for i in range(20):
                    slice = feature[i, :, :]
                    features.append(torch.as_tensor(self.std(self.resize_cv2(slice))))
            else:
                feature = self.std(self.resize_cv2(feature.squeeze()))
                features.append(torch.as_tensor(feature))
        features = torch.stack(features).type(torch.float32)
        return features

    def load_ground_truth(self, ground_truth_path):
        ground_truth = np.load(ground_truth_path)
        ground_truth = torch.tensor(self.std(self.resize_cv2(ground_truth)), dtype=torch.float32)
        return ground_truth

    def Prediction(self, irdrop_threshold):
        self.irdrop_threshold = irdrop_threshold
        with torch.cuda.amp.autocast() if self.device != 'cpu' else torch.no_grad():
            self.pred = self.model(self.feature)
            self.pred = self.model.sigmoid(self.pred)
            self.pred = F.interpolate(self.pred, size=(256, 256), mode='bilinear', align_corners=False)
        return self.pred

    def compare_prediction_with_ground_truth(self, fig_save_path=None):
        # Ensure both prediction and ground truth are available
        if self.ground_truth is None or self.pred is None:
            raise ValueError("Either prediction or ground truth data is missing.")
        
        # Plot prediction vs. ground truth
        plt.figure(figsize=(10, 5))
        # Predicted IR drop plot
        plt.subplot(1, 2, 1)
        plt.imshow(self.pred[0, 0].detach().cpu().numpy(), cmap='jet')
        plt.title("Predicted IR Drop")
        plt.colorbar(label='Predicted IR Drop')
        
        # Ground truth IR drop plot
        plt.subplot(1, 2, 2)
        plt.imshow(self.ground_truth.detach().cpu().numpy(), cmap='jet')
        plt.title("Ground Truth IR Drop")
        plt.colorbar(label='Ground Truth IR Drop')

        plt.tight_layout()
        if fig_save_path:
            plt.savefig(f"{fig_save_path}/IRDrop_Comparison.png")
        plt.show()

    def save(self, output_path):
        np.save(f"{output_path}/PredArray", self.pred[0, 0].detach().cpu().numpy())
        if self.ground_truth is not None:
            np.save(f"{output_path}/GroundTruthArray", self.ground_truth.detach().cpu().numpy())


def parse_args():
    description = "Input the Path for Prediction"
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--data_path", default="./data/1", type=str, help='The path of the data file')
    parser.add_argument("--fig_save_path", default="./predict_save_img", type=str, help='The path to save the figure')
    parser.add_argument("--weight_path", default="./model_weight/irdrop_train_weights.pt", type=str, help='The path of the model weight')
    parser.add_argument("--output_path", default="./output", type=str, help='The output path')
    parser.add_argument("--irdrop_threshold", default=0.1, type=float, help='irdrop_threshold [0,1]')
    parser.add_argument("--device", default='cpu', type=str, help='If you have GPU, type "cuda" for faster execution')
    parser.add_argument("--ground_truth_path", default="./output/10.npy", type=str, help='The path of the original IR drop data file')
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = parse_args()
    feature_list = ['power_i', 'power_s', 'power_sca', 'power_all', 'power_t', 'VDD_Map', 'decap']

    predictionSystem = IRDropPrediction(datapath=args.data_path, features=feature_list,
                                        model_path=args.weight_path, device=args.device,
                                        ground_truth_path=args.ground_truth_path)
    pred = predictionSystem.Prediction(irdrop_threshold=args.irdrop_threshold)
    predictionSystem.save(args.output_path)

    # Plot and compare prediction with ground truth if path is provided
    if args.fig_save_path:
        predictionSystem.compare_prediction_with_ground_truth(fig_save_path=args.fig_save_path)
