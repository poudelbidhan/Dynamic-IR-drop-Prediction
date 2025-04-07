import numpy as np
import os, re, bisect, gzip, csv, math, binascii
import glob
import concurrent.futures


def instance_direction_rect(line): # used when we only need bounding box (rect) of the cell.

    if 'N' in line or 'S' in line:
        m_direction = (1, 0, 0, 1)
    elif 'W' in line or 'E' in line:
        m_direction = (0, 1, 1, 0)
    else:
        raise ValueError('read_macro_direction_wrong')
    return m_direction




def instance_direction_bottom_left(direction): # used when we need to get the bottom left corner of the cell.
    if   direction == 'N':
        i_direction = (0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0)
    elif direction == 'S':
        i_direction = (-1, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 1)
    elif direction ==  'W':
        i_direction = (0, -1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0)
    elif direction ==  'E':
        i_direction = (0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 1, 0)
    elif direction == 'FN':
        i_direction = (-1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0)
    elif direction == 'FS':
        i_direction = (0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 1)
    elif direction == 'FW':
        i_direction = (0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0)
    elif direction == 'FE':
        i_direction = (0, -1, -1, 0, 0, 0, 0, 0, 0, 1, 1, 0)
    else:
        raise ValueError('read_macro_direction_wrong')
    return i_direction




def my_range(start, end):
    if start == end:
        return [start]
    if start != end:
        return range(start, end)



def save(root_path, dir_name, save_name, data):
    save_path = os.path.join(root_path, dir_name, save_name)
    if not os.path.exists(os.path.dirname(save_path)):
        os.makedirs(os.path.dirname(save_path))
    np.save(save_path, data)

def save_npz(root_path, dir_name, save_name, data):
    save_path = os.path.join(root_path, dir_name, save_name)
    if not os.path.exists(os.path.dirname(save_path)):
        os.makedirs(os.path.dirname(save_path))
    np.savez_compressed(save_path, data)



def divide_list(list, n):
    for i in range(0, len(list), n):
        yield list[i:i + n]




def divide_n(list_in, n):
    list_out = [ [] for i in range(n)]
    for i,e in enumerate(list_in):
        list_out[i%n].append(e)
    return list_out



def is_gzip_file(file_path):
    with open(file_path, 'rb') as file:
        header = file.read(2)
    hex_header = binascii.hexlify(header).decode('utf-8')
    if hex_header == '1f8b':
        return True
    else:
        return False





## Lef related functions

def polygon_to_bounding_rectangle(polygon):
    xs = polygon[0::2]
    ys = polygon[1::2]
    x_min = min(xs)
    y_min = min(ys)
    x_max = max(xs)
    y_max = max(ys)
    return [x_min, y_min, x_max, y_max]



def read_lef(path, lef_dict, unit):
    with open(path, 'r') as read_file:
        cell_name = ''
        pin_name = ''
        polygons = []
        rect_list_left = []
        rect_list_lower = []
        rect_list_right = []
        rect_list_upper = []
        READ_MACRO = False
        for line in read_file:
            if line.lstrip().startswith('MACRO'):
                READ_MACRO = True
                cell_name = line.split()[1]
                lef_dict[cell_name] = {}
                lef_dict[cell_name]['pin'] = {}
                lef_dict[cell_name]['type'] = 'std_cell'

            if READ_MACRO:
                if line.lstrip().startswith('SIZE'):
                    l = re.findall(r'-?\d+\.?\d*e?-?\d*?', line)
                    lef_dict[cell_name]['size'] = [unit * float(l[0]), unit * float(l[1])]  # size [unit*w,unit*h]

                elif line.lstrip().startswith('PIN'):
                    pin_name = line.split()[1]
                    polygons = []
                    rect_list_left = []
                    rect_list_lower = []
                    rect_list_right = []
                    rect_list_upper = []

                elif line.lstrip().startswith('RECT'):
                    l = re.findall(r'-?\d+\.?\d*e?-?\d*?', line)
                    rect_left = float(l[0]) * unit
                    rect_lower = float(l[1]) * unit
                    rect_right = float(l[2]) * unit
                    rect_upper = float(l[3]) * unit
                    rect_list_left.append(rect_left)
                    rect_list_lower.append(rect_lower)
                    rect_list_right.append(rect_right)
                    rect_list_upper.append(rect_upper)

                elif line.lstrip().startswith('POLYGON'):
                    l = re.findall(r'-?\d+\.?\d*e?-?\d*?', line)
                    polygon = [unit * float(coord) for coord in l]
                    polygons.append(polygon)

                elif line.lstrip().startswith(f'END {pin_name}'):
                    if rect_list_left and rect_list_lower and rect_list_right and rect_list_upper:
                        rect_left = min(rect_list_left)
                        rect_lower = min(rect_list_lower)
                        rect_right = max(rect_list_right)
                        rect_upper = max(rect_list_upper)
                        lef_dict[cell_name]['pin'][pin_name] = [rect_left, rect_lower, rect_right, rect_upper]  # pin_rect
                    elif polygons:
                        for polygon in polygons:
                            bounding_rect = polygon_to_bounding_rectangle(polygon)
                            lef_dict[cell_name]['pin'][pin_name] = bounding_rect
                    rect_list_left = []
                    rect_list_lower = []
                    rect_list_right = []
                    rect_list_upper = []
                    polygons = []

    return lef_dict






def read_lef_pin_map(path, lef_dic, unit):
    with open(path, 'r') as read_file:
        cell_name = ''
        pin_name = ''
        READ_MACRO = False

        for line in read_file:
            if line.lstrip().startswith('MACRO'):
                cell_name = line.split()[1]
                lef_dic[cell_name] = {}
                lef_dic[cell_name]['pin'] = {}
                READ_MACRO = True

            if READ_MACRO:

                if line.lstrip().startswith('SIZE'):
                    l = re.findall(r'-?\d+\.?\d*e?-?\d*?', line)
                    lef_dic[cell_name]['size'] = [unit * float(l[0]), unit * float(l[1])]

                elif line.lstrip().startswith('PIN') or line.lstrip().startswith('OBS'):
                    if line.lstrip().startswith('OBS'):
                        pin_name = 'OBS'
                    else:
                        pin_name = line.split()[1]
                    lef_dic[cell_name]['pin'][pin_name] = {}

                elif line.lstrip().startswith('LAYER'):
                    pin_layer = line.split()[1]
                    lef_dic[cell_name]['pin'][pin_name][pin_layer] = []

                elif line.lstrip().startswith('RECT'):
                    l = line.split()
                    lef_dic[cell_name]['pin'][pin_name][pin_layer].append([float(l[1])* unit,float(l[2])* unit,float(l[3])* unit,float(l[4])* unit])

    return lef_dic








## DEF file reading and processing functions

def read_route_def(route_def_path):
    gcell_size = [-1, -1]
    gcell_coordinate_x = []
    gcell_coordinate_y = []
    GCELLX = []
    GCELLY = []
    route_instance_dict = {}
    route_net_dict = {}
    route_pin_dict = {}

    if is_gzip_file(route_def_path):
        read_file = gzip.open(route_def_path, "rt")
    else:
        read_file = open(route_def_path, "r")

    READ_GCELL = False
    READ_MACROS = False
    READ_NETS = False
    READ_PINS = False
    net = ''
    for line in read_file:
        line = line.lstrip()
        if line.startswith("COMPONENTS"):
            READ_MACROS = True
        elif line.startswith("END COMPONENTS"):
            READ_MACROS = False
        elif line.startswith("NETS"):
            READ_NETS = True
        elif line.startswith("END NETS") or line.startswith("SPECIALNETS"):
            READ_NETS = False
        elif line.startswith('PIN'):
            READ_PINS = True
        elif line.startswith('END PINS'):
            READ_PINS = False
        elif line.startswith("GCELLGRID"):
            READ_GCELL = True
        elif line.startswith("VIAS"):
            READ_GCELL = False
            if len(GCELLX) <= 2:
                raise ValueError("Invalid GCELL data")
            if int(GCELLX[0][0]) < int(GCELLX[-1][0]):
                GCELLX.reverse()
                GCELLY.reverse()

            top = GCELLY.pop()
            for i in range(top[1] - 1):
                gcell_coordinate_y.append(top[0] + (i + 1) * top[2])
            for i in range(len(GCELLY)):
                top = GCELLY.pop()
                for _ in range(top[1]):
                    gcell_coordinate_y.append(gcell_coordinate_y[-1] + top[2])
            gcell_coordinate_y = np.array(gcell_coordinate_y)

            top = GCELLX.pop()
            for i in range(top[1] - 1):
                gcell_coordinate_x.append(top[0] + (i + 1) * top[2])
            for i in range(len(GCELLX)):
                top = GCELLX.pop()
                for _ in range(top[1]):
                    gcell_coordinate_x.append(gcell_coordinate_x[-1] + top[2])
            gcell_coordinate_x = np.array(gcell_coordinate_x)

        if READ_GCELL:  # get gcell_coordinate
            instance = line.split()
            if len(instance) != 8:
                continue
            gcell = [int(instance[2]), int(instance[4]), int(instance[6])]  # at x do y step z
            if 'Y' in line:
                gcell_size[1] += int(instance[4])
                GCELLY.append(gcell)
            elif 'X' in line:
                gcell_size[0] += int(instance[4])
                GCELLX.append(gcell)

        if READ_MACROS:  # get route_instance_dict
            if "FIXED" in line or "PLACED" in line:
                instance = line.split()
                l = instance.index('(')
                route_instance_dict[instance[1].replace('\\', '')] = [instance[2], (int(instance[l+1]), int(instance[l+2])), instance[l+4]]

        if READ_NETS:
            if line.startswith('-'):
                net = line.split()[1].replace('\\', '')  # get route_net_dict
                route_net_dict[net] = []

            elif line.startswith('('):  # get pin names in each net
                l = line.split()
                n = 0
                for k in l:
                    if k == '(':
                        #here, there can be some changes or something wrong but it is working as it is so, i'm keep the original code 
                        #pin_name = l[n + 1] + ' ' + l[n + 2] if l[n + 1] == 'PIN' else l[n + 1]
                        #route_net_dict[net].append(pin_name.replace('\\', ''))
                        route_net_dict[net].append(l[n + 1].replace('\\', ''))
                    n += 1

        if READ_PINS:  # get route_pin_dict (for primary IO pins)
            if line.startswith('-'):
                pin = line.split()[1]
            elif line.strip().startswith('+ LAYER'):
                pin_rect = re.findall(r'\d+', line)
                route_pin_dict[pin] = {}
                route_pin_dict[pin]['layer'] = line.split()[2]
                route_pin_dict[pin]['rect'] = [int(pin_rect[-4]), int(pin_rect[-3]), int(pin_rect[-2]), int(pin_rect[-1])]
            elif line.strip().startswith('+ PLACED'):
                data = line.split()
                route_pin_dict[pin]['location'] = [int(data[3]), int(data[4])]
                route_pin_dict[pin]['direction'] = data[6]
    read_file.close()

    return {
        'gcell_size': gcell_size,
        'gcell_coordinate_x': gcell_coordinate_x,
        'gcell_coordinate_y': gcell_coordinate_y,
        'route_instance_dict': route_instance_dict,
        'route_net_dict': route_net_dict,
        'route_pin_dict': route_pin_dict
    }






## Functions related to power and time-window calculations

def read_twf(twf_path, route_net_dict, n_time_window):
    tw_dict = {}
    with open(twf_path, 'r') as read_file: 
        for line in read_file:
            if "WAVEFORM" in line:
                clk_data = line.split()
              #  clk = int(float(clk_data[2])) ##here was the major problem for my script, my clk was 0.5000 and it was getting converted to 0
                ## which is not what I wanted , changing to just float, have given some variety in timwing window but not much 
                clk = float(clk_data[2])
                time_windows = np.linspace(-1, clk, n_time_window + 1)
                time_windows = np.delete(time_windows, 0)
                #print(time_windows)
                #print(clk)
                #print(clk_data[2])
            elif "NET" in line:
                if "CONSTANT" in line:
                    data = line.split()
                    name = data[2].replace('\\', '').replace('"', '')
                    pin_list = route_net_dict[name]
                    for cell_name in pin_list:
                        if cell_name not in tw_dict:
                            tw_dict[cell_name] = []
                        tw_dict[cell_name].append(0)
                else:
                    data = line.split()
                    if data[2] == '*' or data[6] == '*':
                        name = data[1].replace('\\', '').replace('"', '')
                       
                        pin_list = route_net_dict[name]
                        for cell_name in pin_list:
                            if cell_name not in tw_dict:
                                tw_dict[cell_name] = []
                            tw_dict[cell_name].append(0)
                    else:
                        name = data[1].replace('\\', '').replace('"', '')
                        #print(name)
                        #print(route_net_dict[name[0]])
                        pin_list = route_net_dict[name]
                        #print(pin_list)
                      
                        time_arrive = data[2].split(':')
                        time_arrive.extend(data[6].split(':'))
                        time_arrive = [float(i) for i in time_arrive]
                        time_arrive_window = [min(time_arrive), max(time_arrive)]
                        tw_result = [bisect.bisect_left(time_windows, time_arrive_window[0]), bisect.bisect_left(time_windows, time_arrive_window[1])]
                        #print( name)
                        #print (time_arrive_window)
                        #print(tw_result)
                        
                        for cell_name in pin_list:
                            if cell_name not in tw_dict:
                                tw_dict[cell_name] = []
                            tw_dict[cell_name].append(tw_result)
    return tw_dict





def read_power(power_path, lef_dict, tw_dict):
    power_dict = {}
    
    with open(power_path, 'r') as read_file:
        start = False
        read = False
        for line in read_file:
            if "Instance" in line:
                start = True
            if start and line.startswith('Total'):
                break
            if start:
                if line.startswith('-'):
                    read = True
                if read:
                    if len(line.split()) == 1:
                        name = line.split()[0].replace('\\', '')
                    elif len(line.split()) == 8:
                        if line.split()[-1] not in lef_dict or not lef_dict[line.split()[-1]]['type'] == 'std_cell':
                            continue
                        data = line.split()
                        if eval(data[0]) == 0:
                            if 'FILLER' in name:
                                power_dict[name] = [0, float(data[2]), float(data[3]), float(data[4]), 'filler']
                            else:
                                power_dict[name] = [0, float(data[2]), float(data[3]), float(data[4]), tw_dict[name]]
                        else:
                            power_dict[name] = [eval(data[1])/eval(data[0]), float(data[2]), float(data[3]), float(data[4]), tw_dict[name]]
                    elif len(line.split()) == 9:
                        if line.split()[-1] not in lef_dict or not lef_dict[line.split()[-1]]['type'] == 'std_cell':
                            continue
                        data = line.split()
                        name = data[0].replace('\\', '')
                        if eval(data[1]) == 0:
                            if 'FILLER' in name:
                                power_dict[name] = [0, float(data[3]), float(data[4]), float(data[5]), 'filler']
                            else:
                                power_dict[name] = [0, float(data[3]), float(data[4]), float(data[5]), tw_dict[name]]
                        else:
                            power_dict[name] = [eval(data[2])/eval(data[1]), float(data[3]), float(data[4]), float(data[5]), tw_dict[name]]
    
    return power_dict


## Power density functions

def compute_density_with_overlap(density, location_on_coordinate, location_on_gcell, gcell_coordinate_x, gcell_coordinate_y):
    x_left, y_lower, x_right, y_upper = location_on_coordinate
    gcell_left, gcell_lower, gcell_right, gcell_upper = location_on_gcell
    
    if gcell_left == gcell_coordinate_x.size:
        gcell_left = gcell_left - 1
    if gcell_lower == gcell_coordinate_y.size:
        gcell_lower = gcell_lower - 1
    if gcell_right == gcell_coordinate_x.size:
        gcell_right = gcell_right - 1
    if gcell_upper == gcell_coordinate_y.size:
        gcell_upper = gcell_upper - 1

    if x_left == gcell_coordinate_x[gcell_left - 1]:
        gcell_left = gcell_right
    if y_lower == gcell_coordinate_y[gcell_lower - 1]:
        gcell_lower = gcell_upper
    
    for j in my_range(gcell_left, gcell_right):
        for k in my_range(gcell_lower, gcell_upper):
            if j == 0:
                left = -10  # the border of die is -10
            else:
                left = gcell_coordinate_x[j - 1]
            if k == 0:
                lower = -10
            else:
                lower = gcell_coordinate_y[k - 1]
            right = gcell_coordinate_x[j]
            upper = gcell_coordinate_y[k]
            if (right - left) * (upper - lower) == 0:
                print(right, left)
            overlap = ((min(right, x_right) - max(left, x_left)) * (min(upper, y_upper) - max(lower, y_lower))) / ((right - left) * (upper - lower))
            density[j, k] += overlap
    
    return density





def get_power_map(power_dict, route_instance_dict, lef_dict, gcell_coordinate_x, gcell_coordinate_y, gcell_size, n_time_window):
    window_shape = [n_time_window]
    window_shape.extend(gcell_size)
    power_t = np.zeros(window_shape)
    power_i = np.zeros(gcell_size)
    power_s = np.zeros(gcell_size)
    power_sca = np.zeros(gcell_size)
    power_all = np.zeros(gcell_size)
    power_map = np.zeros(gcell_size)

    for k, v in power_dict.items():
        if v[4] == 'filler':
            tw = [0]
        else:
            tw = v[4]
        instance = route_instance_dict[k]
        cell_size = lef_dict[instance[0]]['size']
        direction = instance_direction_rect(instance[2])
        cell_x_left = instance[1][0]
        cell_y_lower = instance[1][1]
        cell_x_right = cell_x_left + cell_size[0] * direction[0] + cell_size[1] * direction[1]
        cell_y_upper = cell_y_lower + cell_size[0] * direction[2] + cell_size[1] * direction[3]
        cell_x_left_gcell = bisect.bisect_left(gcell_coordinate_x, cell_x_left)
        cell_y_lower_gcell = bisect.bisect_left(gcell_coordinate_y, cell_y_lower)
        cell_x_right_gcell = bisect.bisect_left(gcell_coordinate_x, cell_x_right)
        cell_y_upper_gcell = bisect.bisect_left(gcell_coordinate_y, cell_y_upper)
        location = [cell_x_left, cell_y_lower, cell_x_right, cell_y_upper]
        location_gcell = [cell_x_left_gcell, cell_y_lower_gcell, cell_x_right_gcell, cell_y_upper_gcell]
        tmp_power_map = np.zeros(gcell_size)
        power_map += compute_density_with_overlap(tmp_power_map, location, location_gcell,gcell_coordinate_x, gcell_coordinate_y)
        n_pin = len(tw)
        power_i += power_map * v[1] * n_pin
        power_s += power_map * v[2] * n_pin
        power_sca += power_map * ((v[1] + v[2]) * v[0] + v[3]) * n_pin
        power_all += power_map * (v[1] + v[2] + v[3]) * n_pin
        if tw:
            for i in tw:
                if i == 0:
                    pass
                else:
                    power_t[i[0]:i[1]+1, :, :] += power_map * ((v[1] + v[2]) * v[0] + v[3])

    return power_t, power_i, power_s, power_sca, power_all


## Decap map generation functions
#read_decap : extract the decap position from .def and find it's capacitance size and its physical dimension from lef

def create_decap_map(route_instance_dict, lef_dict):
    # Example decap_value dictionary
    decap_value = {
        'DECAP2': 1.2,
        'DECAP3': 2.4,
        'DECAP4': 2.5,
        'DECAP5': 1.2,
        'DECAP6': 1.1,
        'DECAP7': 1.0,
        'DECAP8': 0.5,
        'DECAP9': 0.5,
        'DECAP10': 1.0
    }

    decap_map = {}

    for instance, details in route_instance_dict.items():
        cell_name = details[0]
        location = details[1]
        direction = details[2]

        # Check if the cell is a decap
        if 'DECAP' in cell_name:
            size = lef_dict[cell_name]['size']
            capacitance = decap_value.get(cell_name, None)
            decap_map[instance] = {
                'cell_name': cell_name,
                'location': location,
                'size': size,
                'direction': direction,
                'capacitance': capacitance
            }

    return decap_map


def get_decap_position_map(decap_map, gcell_coordinate_x, gcell_coordinate_y, gcell_size):
    decap_position_map = np.zeros(gcell_size)

    for instance, details in decap_map.items():
        cell_size = details['size']
        cell_name = details ['cell_name']
        direction = instance_direction_rect(details['direction'])
        cell_x_left = details['location'][0]
        cell_y_lower = details['location'][1]
        
        cell_x_right = cell_x_left + cell_size[0] * direction[0] + cell_size[1] * direction[1]
        cell_y_upper = cell_y_lower + cell_size[0] * direction[2] + cell_size[1] * direction[3]

        
        cell_x_left_gcell = bisect.bisect_left(gcell_coordinate_x, cell_x_left)
        cell_y_lower_gcell = bisect.bisect_left(gcell_coordinate_y, cell_y_lower)
        cell_x_right_gcell = bisect.bisect_left(gcell_coordinate_x, cell_x_right)
        cell_y_upper_gcell = bisect.bisect_left(gcell_coordinate_y, cell_y_upper)

        location = [cell_x_left, cell_y_lower, cell_x_right, cell_y_upper]
        location_gcell = [cell_x_left_gcell, cell_y_lower_gcell, cell_x_right_gcell, cell_y_upper_gcell]
        
        # Fill the grid cells corresponding to the decap cell location
        for x in range(cell_x_left_gcell, cell_x_right_gcell + 1):
            for y in range(cell_y_lower_gcell, cell_y_upper_gcell + 1):
                decap_position_map[x, y] += details['capacitance']
    
    return decap_position_map




    
def get_IR(gcell_size,gcell_coordinate_x, gcell_coordinate_y,ir_path):
    ir_map = np.zeros(gcell_size)
    with open(ir_path, 'r') as read_file:
        read = False
        for line in read_file:
            if line.startswith('Range'):
                read = False
            if read:
                data = line.split()
                if len(data) >= 5:  # Ensure there are enough columns to avoid IndexError
                    ir_value = float(data[0])
                    metal_layer = data[1]
                    x_coord = float(data[2]) * unit_value
                    y_coord = float(data[3]) * unit_value
                    gcell_x = bisect.bisect_left(gcell_coordinate_x, x_coord)
                    gcell_y = bisect.bisect_left(gcell_coordinate_y, y_coord)
                    if ir_value > ir_map[gcell_x, gcell_y]:
                        ir_map[gcell_x, gcell_y] = ir_value
            if line.startswith('ir'):
                read = True

    return ir_map 


## Power pad distance mapping functions

# Function to calculate Euclidean distance
def euclidean_distance(x1, y1, x2, y2):
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)

# Function to read power pad location files (.pp files)
# Function to read power pad location files (.pp files)
def read_power_pad_files(pp_pattern):
    power_pads = []
    for pp_file in glob.glob(pp_pattern):  # Match all files with the given pattern (e.g., VDD*, VSS*)
        with open(pp_file, 'r') as f:
            reader = csv.reader(f, delimiter='\t')  # Assuming tab-separated file
            next(reader)  # Skip the header line
            for row in reader:
                pad_name = row[0]
                x = float(row[1]) * unit_value
                y = float(row[2]) * unit_value
                layer_name = row[3]
                power_pads.append((pad_name, x, y, layer_name))
    return power_pads



# Function to create separate VDD and VSS power pad distance maps
def get_power_pad_distance_maps(route_instance_dict, vdd_pads, gcell_coordinate_x, gcell_coordinate_y, gcell_size):
    vdd_distance_map = np.zeros(gcell_size)  # VDD distance map
    #vss_distance_map = np.zeros(gcell_size)  # VSS distance map

    # Iterate over instances in route_instance_dict
    for instance, details in route_instance_dict.items():
        cell_x_left = details[1][0]  # x-coordinate of instance
        cell_y_lower = details[1][1]  # y-coordinate of instance

        # Find the grid cell for the instance using binary search
        cell_x_gcell = bisect.bisect_left(gcell_coordinate_x, cell_x_left)
        cell_y_gcell = bisect.bisect_left(gcell_coordinate_y, cell_y_lower)

        # Calculate minimum distance to VDD pads
        min_vdd_distance = min(euclidean_distance(cell_x_left, cell_y_lower, vdd_x, vdd_y) for _, vdd_x, vdd_y, _ in vdd_pads)

        # Calculate minimum distance to VSS pads
        #min_vss_distance = min(euclidean_distance(cell_x_left, cell_y_lower, vss_x, vss_y) for _, vss_x, vss_y, _ in vss_pads)

        # Assign the distances to the corresponding grid cell
        vdd_distance_map[cell_x_gcell, cell_y_gcell] = min_vdd_distance  # VDD distance
        #vss_distance_map[cell_x_gcell, cell_y_gcell] = min_vss_distance  # VSS distance

    return vdd_distance_map

 

def process_folder(folder_path):
    folder_name = os.path.basename(folder_path)
    output_path = os.path.join('/mnt/research/Hu_Jiang/Students/Poudel_Bidhan/extracted_features2', folder_name)
    try:
        if not os.path.exists(output_path):
            os.makedirs(output_path)

        # Check if the LEF file exists
        lef_path = 'LEF/gsclib045_macro.lef'
        if not os.path.exists(lef_path):
            raise FileNotFoundError(f"LEF file not found: {lef_path}")
        lef_dict = {}
        lef_dict = read_lef(lef_path, lef_dict, unit_value)
        print("LEF file processed")


        lef_dic = {}
        lef_dic = read_lef_pin_map(lef_path, lef_dic, unit_value)

        
        # Check if the .DEF file exists
        route_def_path = os.path.join(folder_path, 'detailed_route.def.gz')
        if not os.path.exists(route_def_path):
            raise FileNotFoundError(f".DEF file not found: {route_def_path}")
        result = read_route_def(route_def_path)
        print(".DEF file processed")

        # Access the results from the .DEF file
        gcell_size = result['gcell_size']
        gcell_coordinate_x = result['gcell_coordinate_x']
        gcell_coordinate_y = result['gcell_coordinate_y']
        route_instance_dict = result['route_instance_dict']
        route_net_dict = result['route_net_dict']
        route_pin_dict = result['route_pin_dict']

        # Check if the .twf file exists
        twf_path = os.path.join(folder_path, 'cts.twf')
        if not os.path.exists(twf_path):
            raise FileNotFoundError(f".twf file not found: {twf_path}")
        n_time_window = 20
        tw_dict = read_twf(twf_path, route_net_dict, n_time_window)
        print(".twf file processed")


        
        # Check if the power file exists
        power_path = os.path.join(folder_path, 'dyn_power.rpt')
        if not os.path.exists(power_path):
            raise FileNotFoundError(f"Power report file not found: {power_path}")
        power_dict = read_power(power_path, lef_dict, tw_dict)
        print("Power file processed")

        # Generate power maps
        power_t, power_i, power_s, power_sca, power_all = get_power_map(
            power_dict, route_instance_dict, lef_dict, 
            gcell_coordinate_x, gcell_coordinate_y, gcell_size, n_time_window=20
        )
        save(output_path, 'power_t', 'power_t', power_t)
        save(output_path, 'power_i', 'power_i', power_i)
        save(output_path, 'power_s', 'power_s', power_s)
        save(output_path, 'power_sca', 'power_sca', power_sca)
        save(output_path, 'power_all', 'power_all', power_all)
        print("Power maps generated and saved")

        # Generate decap position map
        decap_map = create_decap_map(route_instance_dict, lef_dict)
        decap_position_map = get_decap_position_map(decap_map, gcell_coordinate_x, gcell_coordinate_y, gcell_size)
        save(output_path, 'decap', 'decap', decap_position_map)
        print("Decap position map saved")

        # Generate power pad distance maps
        vdd_pads = read_power_pad_files(os.path.join(folder_path, "VDD*.pp"))
        #vss_pads = read_power_pad_files(os.path.join(folder_path, "VSS*.pp"))
        vdd_distance_map = get_power_pad_distance_maps(
            route_instance_dict, vdd_pads, gcell_coordinate_x, gcell_coordinate_y, gcell_size
        )
        save(output_path, 'VDD_Map', 'vdd_map', vdd_distance_map)
        #save(output_path, 'VSS_Map', 'vss_map', vss_distance_map)
        print("Power pad distance maps saved")

        # Perform IR mapping
        ir_path = os.path.join(folder_path, 'route_dynamic_ir.rpt')
        if not os.path.exists(ir_path):
            raise FileNotFoundError(f"IR drop file not found: {ir_path}")
        ir_map = get_IR(gcell_size, gcell_coordinate_x, gcell_coordinate_y, ir_path)
        
        save(output_path, 'IR_drop', 'ir_map', ir_map)
        print("IR map generated and saved")

        # Final print statement
        print(f"Processed {folder_name}")

    except Exception as e:
        print(f"Error processing folder {folder_name}: {e}")

# Your process_folder function here
unit_value = 2000
if __name__ == '__main__':
    # Correctly get the list of subfolders under 'data/' using glob
    folder_paths = glob.glob('/mnt/research/Hu_Jiang/Students/Poudel_Bidhan/data1/home/grads/b/bidhanpoudel/Design-files/Data/*')  # This will return a list of subfolder paths
    # Print folder paths for debugging
    print(f"Processing the following folders: {folder_paths}")

    # Parallel processing to handle multiple folders
    with concurrent.futures.ProcessPoolExecutor() as executor:
        executor.map(process_folder, folder_paths)