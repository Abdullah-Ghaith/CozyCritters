## AnimData.gd
## A small Resource describing a single animation strip on a spritesheet.
## Nested inside AnimalDefinition.animations dictionary.
## Example key names: "walk", "idle", "sleep", "interact"
class_name AnimData
extends Resource

## Index of the first frame on the spritesheet (0-based, left-to-right, top-to-bottom)
@export var first_frame: int = 0

## How many frames this animation uses
@export var frame_count: int = 1

## Playback speed in frames per second
@export var fps: float = 8.0

## Whether the animation loops
@export var looping: bool = true
