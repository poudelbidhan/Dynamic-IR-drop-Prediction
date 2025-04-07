import os
from multiprocessing import Process
import argparse
from src.util import divide_n
from src.read import ReadInnovusOutput, read_lef, read_lef_pin_map

class Paraser(object):
    def __init__(self) -> None:
        self.parser = argparse.ArgumentParser()
        self.parser.add_argument('--data_root', default='/home/grads/b/bidhanpoudel/ML_CAD/feature_extraction2', help='the parent dir of innovus workspace')
        self.parser.add_argument('--lef_path', default= ['/home/grads/b/bidhanpoudel/ML_CAD/feature_extraction/LEF/circuitnet.lef'], help='path to LEF files')
        self.parser.add_argument('--unit', default=2000, help='unit defined in the beginning of DEF')
        self.parser.add_argument('--save_path', default='./out', help='save path')
        self.parser.add_argument('--process_capacity', default=10, help='multi-process setting, number of files for each process, determine number of process')
        self.parser.add_argument('--debug', default= False, help='disable multi-process to use pdb')

        self.parser.add_argument('--route_def_name', default='detailed_route.def.gz')

        self.parser.add_argument('--twf_rpt_name', default='cts.twf', help='timing window file name from write_timing_windows')
        self.parser.add_argument('--power_rpt_name', default='dyn_power.rpt', help='power report file name from report_power')
        self.parser.add_argument('--ir_rpt_name', default='route_dynamic_ir.rpt', help='IR report file name from report_power_rail_results')
        self.parser.add_argument('--n_time_window', default='20', help='number of divided timing windows')
        self.parser.add_argument('--scaling', default=None, help='scaling factor for coordinates')

def read(read_list, arg, lef_dic, lef_dic_jnet):

    for path in read_list:
        path = os.path.join(arg.data_root, path)
        save_name = os.path.basename(path)
        process_log = ReadInnovusOutput(path, arg, save_name, lef_dic)
        process_log.read_route_def()   
        process_log.get_IR_features()


if __name__ == '__main__':
    argp = Paraser()
    arg = argp.parser.parse_args()
    if not os.path.exists(arg.save_path):
        os.makedirs(arg.save_path)
    lef_dic = {}
    lef_dic_jnet = {}
    for i in arg.lef_path:
        lef_dic = read_lef(i, lef_dic, arg.unit)
        lef_dic_jnet = read_lef_pin_map(i, lef_dic_jnet, arg.unit)

    read_list = os.listdir(arg.data_root)
    nlist = divide_n(read_list, arg.process_capacity) 

    if arg.debug:
        read(read_list, arg, lef_dic,lef_dic_jnet)
    else:
        process = []
        for divided_list in nlist:
            p = Process(target=read, args=(divided_list, arg, lef_dic, lef_dic_jnet))
            process.append(p)
        for p in process:
            p.start()
        for p in process:
            p.join()
