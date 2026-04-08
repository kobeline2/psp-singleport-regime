# local/settings/

This folder is for gitignored script-specific local settings.

Students and project members can create small override files here so they do not need to edit the shared scripts every time they change `runID`, frame ranges, or temporary PIVLab options.

## Current Supported Local Settings File

- `s10_prepare_frames_local.m`

This file is optional. If it exists, `scripts/s10_prepare_frames.m` loads it after defining the default values in the shared script.

## Example

Create:

`local/settings/s10_prepare_frames_local.m`

with content such as:

```matlab
runID = "R0009";
do_select_rectification = false;
make_pivlab_tmp = true;
pivlab_variant = "long";

opts.frame_step = 6;
opts.end_frame = Inf;

pivlab_opts.frame_step = 5;
pivlab_opts.start_index = 1000;
```

## Recommended Usage

- Only override the values you need for the current run.
- Prefer changing individual fields like `opts.frame_step` instead of replacing the whole struct.
- Do not commit personal local settings files.

## Recommended First Step

Start by copying:

`local/settings/s10_prepare_frames_local.m.example`

to:

`local/settings/s10_prepare_frames_local.m`

and then edit only the lines you want to change.
