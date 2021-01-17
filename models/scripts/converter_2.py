import matplotlib.pyplot as plt
import numpy as np
import cv2
from imageio import imsave
from argparse import ArgumentParser
from pathlib import Path

from copy import deepcopy
from collections import Counter
from sklearn.cluster import KMeans
import cv2


def get_dom_colors(image_path, clusters=10, plot=False):
    image = cv2.imread(image_path)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = image.reshape((image.shape[0] * image.shape[1], 3))
    clt = KMeans(n_clusters=clusters)
    clt.fit(image)
    hist = centroid_histogram(clt)

    dcolors = [c.astype("uint8").tolist() for c in clt.cluster_centers_]
    print(dcolors)
    if plot:
        bar = plot_colors(hist, clt.cluster_centers_)
        plt.figure()
        plt.axis("off")
        plt.imshow(bar)
        plt.show()

    return dcolors


def plot_colors(hist, centroids):
    bar = np.zeros((50, 300, 3), dtype="uint8")
    startX = 0

    for (percent, color) in zip(hist, centroids):
        endX = startX + (percent * 300)
        cv2.rectangle(bar, (int(startX), 0), (int(endX), 50),
                      color.astype("uint8").tolist(), -1)
        startX = endX

    return bar


def centroid_histogram(clt):
    numLabels = np.arange(0, len(np.unique(clt.labels_)) + 1)
    (hist, _) = np.histogram(clt.labels_, bins=numLabels)

    hist = hist.astype("float")
    hist /= hist.sum()

    return hist


def get_vicin_vals(mat, x, y, xyrange):
    width = len(mat[0])
    height = len(mat)
    vicinVals = []
    for xx in range(x - xyrange, x + xyrange + 1):
        for yy in range(y - xyrange, y + xyrange + 1):
            if 0 <= xx < width and 0 <= yy < height:
                vicinVals.append(mat[yy][xx])
    return vicinVals


def smooth(mat):
    width = len(mat[0])
    height = len(mat)
    flat_simp = [Counter(get_vicin_vals(mat, x, y, 4)).most_common(1)[0][0] for y in range(0, height) for x in
                range(0, width)]
    simp = [flat_simp[i:i + height] for i in range(0, len(flat_simp), height)]

    return simp


def neighbors_same(mat, x, y):
    width = len(mat[0])
    height = len(mat)
    val = mat[y][x]
    x_rel = [1, 0]
    y_rel = [0, 1]
    for i in range(0, len(x_rel)):
        xx = x + x_rel[i]
        yy = y + y_rel[i]
        if 0 <= xx < width and 0 <= yy < height:
            if mat[yy][xx] != val:
                return False
    return True


def outline(mat):
    width = len(mat[0])
    height = len(mat)
    line_flat = [0 if neighbors_same(mat, x, y) else 1 for y in range(0, height) for x in range(0, width)]
    line = [line_flat[i:i + height] for i in range(0, len(line_flat), height)]

    return line


def get_region(mat, cov, x, y):
    covered = deepcopy(cov)
    region = {'value': mat[y][x], 'x': [], 'y': []}
    value = mat[y][x]

    queue = [[x, y]]
    while len(queue) > 0:
        coord = queue.pop()
        if covered[coord[1]][coord[0]] == False and mat[coord[1]][coord[0]] == value:
            region['x'].append(coord[0])
            region['y'].append(coord[1])
            covered[coord[1]][coord[0]] = True
            if coord[0] > 0:
                queue.append([coord[0] - 1, coord[1]])
            if coord[0] < len(mat[0]) - 1:
                queue.append([coord[0] + 1, coord[1]])
            if coord[1] > 0:
                queue.append([coord[0], coord[1] - 1])
            if coord[1] < len(mat) - 1:
                queue.append([coord[0], coord[1] + 1])

    return region


def cover_region(covered, region):
    for i in range(0, len(region['x'])):
        covered[region['y'][i]][region['x'][i]] = True


def same_count(mat, x, y, incX, incY):
    value = mat[y][x]
    count = -1
    while 0 <= x < len(mat[0]) and 0 <= y < len(mat) and mat[y][x] == value:
        count += 1
        x += incX
        y += incY

    return count


def get_label_loc(mat, region):
    bestI = 0
    best = 0
    for i in range(0, len(region['x'])):
        goodness = same_count(mat, region['x'][i], region['y'][i], -1, 0) * same_count(mat, region['x'][i],
                                                                                       region['y'][i], 1, 0) * same_count(
            mat, region['x'][i], region['y'][i], 0, -1) * same_count(mat, region['x'][i], region['y'][i], 0, 1)
        if goodness > best:
            best = goodness
            bestI = i

    return {'value': region['value'], 'x': region['x'][bestI], 'y': region['y'][bestI]}


def get_below_value(mat, region):
    x = region['x'][0]
    y = region['y'][0]
    print(region)
    while mat[y][x] == region['value']:
        print(mat[y][x])
        y += 1

    return mat[y][x]


def remove_region(mat, region):
    if region['y'][0] > 0:
        new_value = mat[region['y'][0] - 1][region['x'][0]]
    else:
        new_value = get_below_value(mat, region)
    for i in range(0, len(region['x'])):
        mat[region['y'][i]][region['x'][i]] = new_value


def get_label_locs(mat):
    global region
    width = len(mat[0])
    height = len(mat)
    covered = [[False] * width] * height

    label_locs = []
    for y in range(0, height):
        for x in range(0, width):
            if not covered[y][x]:
                region = get_region(mat, covered, x, y)
                cover_region(covered, region)
            if len(region['x']) > 100:
                label_locs.append(get_label_loc(mat, region))
            else:
                remove_region(mat, region)

    return label_locs


def img_process(mat):
    mat_smooth = smooth(mat)
    mat_line = outline(mat_smooth)
    return mat_smooth, mat_line


def getNearest(palette, col):
    nearest = 0
    nearest_distsq = 1000000
    for i in range(0, len(palette)):
        pcol = palette[i]
        distsq = pow(pcol[0] - col[0], 2) + pow(pcol[1] - col[1], 2) + pow(pcol[2] - col[2], 2)
        if distsq < nearest_distsq:
            nearest = i
            nearest_distsq = distsq

    return nearest


def image_data_to_simp_mat(imgData, palette):
    width = len(imgData[0])
    height = len(imgData)

    flat_mat = [getNearest(palette, xyVal) for yVal in imgData for xyVal in yVal]
    mat = [flat_mat[i:i + height] for i in range(0, len(flat_mat), height)]

    return mat


def mat_to_image_data(mat, palette):
    width = len(mat[0])
    height = len(mat)
    img_flat = [[float(c / 255.0) for c in palette[xyVal]] for yVal in mat for xyVal in yVal]
    img_data = [img_flat[i:i + height] for i in range(0, len(img_flat), height)]

    return img_data


if __name__ == '__main__':
    root_path = Path("converter_2")

    parser = ArgumentParser()
    parser.add_argument(
        '--input', type=str, help='file with input image in RGB workspace',
        metavar='INPUT_FILE', required=True)

    parser.add_argument(
        '--output', type=str, help='output file',
        metavar='OUTPUT_FILE', required=False, default=root_path / "out")

    args = parser.parse_args()

    img_path = str(args.input)

    dom_colors = get_dom_colors(img_path, 20, True)
    palette = dom_colors
    image = cv2.imread(img_path)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    mat = image_data_to_simp_mat(image, palette)
    mat_smooth, mat_line = img_process(mat)

    height = len(mat_line)
    borderFlat = [[abs(xyVal - 1.0) for ii in range(0, 3)] for yVal in mat_line for xyVal in yVal]
    borders = [borderFlat[i:i + height] for i in range(0, len(borderFlat), height)]

    img = np.array(mat_to_image_data(mat_smooth, palette))
    # plt.imshow(PBNImage)
    # plt.show()
    imsave("out-image.jpg", img.astype(np.uint8))
    imsave("out-border.jpg", np.array(borders).astype(np.uint8))
