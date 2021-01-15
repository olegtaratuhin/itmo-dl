# This file contains command line interface to train and save CoreML model

if __name__ == '__main__':

    import os
    import json
    import pathlib
    from argparse import ArgumentParser
    import turicreate as tc

    def next_experiment() -> str:
        for _, dirs, _ in os.walk("experiments"):
            if len(dirs) == 0:
                return "0001"
            sorted_dirs = sorted(dirs)
            last_dir = sorted_dirs[-1]
            num = int(last_dir)
            return f"{num:05d}"

    def record_experiment_input(style_: str, content_: str, validation_: str, experiment_: str, exp_path: pathlib.Path):
        os.makedirs(exp_path)
        with open(exp_path / "input.json", "w") as f:
            config = {
                "style-path": style_,
                "content-path": content_,
                "validation-path": validation_,
                "experiment": experiment_
            }
            json.dump(config, f, ensure_ascii=False, indent=4)

    DATA_PATH = pathlib.Path("../../data")
    TRAIN_PATH = DATA_PATH / "content-images"
    STYLE_PATH = DATA_PATH / "style-images"
    TEST_PATH = DATA_PATH / "sample-images"

    EXPERIMENT_PATH = pathlib.Path("experiments") / next_experiment()

    parser = ArgumentParser()
    parser.add_argument(
        '--experiment', type=str, help='dir to save temporary data',
        metavar='CHECKPOINT_DIR', default=EXPERIMENT_PATH)

    parser.add_argument(
        '--style-images', type=str, help='style image path',
        metavar='STYLE', required=False, default=STYLE_PATH)

    parser.add_argument(
        '--content-images', type=str, help='path to content images',
        metavar='TRAIN_PATH', default=TRAIN_PATH)

    parser.add_argument(
        '--test-images', type=str, help='test image path',
        metavar='TEST', default=False)

    args = parser.parse_args()

    style_path = args.style_images
    content_path = args.content_images
    validation_path = args.test_images
    experiment = args.experiment

    record_experiment_input(str(style_path),
                            str(content_path),
                            str(validation_path), str(experiment),
                            experiment)

    styles = tc.load_images(style_path)
    content = tc.load_images(content_path)
    if validation_path:
        validation = tc.load_images(validation_path)

    model_path = EXPERIMENT_PATH / "_model.model"
    coreml_path = EXPERIMENT_PATH / "_model.mlmodel"

    print("Starting to train model")
    model = tc.style_transfer.create(
        styles, content,
        max_iterations=30000,
        _advanced_parameters={
            "style_loss_mult": [1e-3, 1e-3, 1e-3, 1e-3],
            "use_augmentation": True
        })
    print("Model training finished")

    model.save(model_path)
    model.export_coreml(coreml_path)

    if validation_path:
        # noinspection PyUnboundLocalVariable
        stylized_images = model.stylize(validation)
        stylized_images.explore()
