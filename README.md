# MSL-Photoshop-Plugin

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

### Usage
	
	$ cp -R ./bin/metal.plugin "/Applications/Adobe Photoshop CC 2018/Plug-ins" 
   	$ open "/Applications/Adobe Photoshop CC 2018/Adobe Photoshop CC 2018.app"
	
`Filter` > `mizt` > `metal`


### Edit

	$ cd "/Applications/Adobe Photoshop CC 2018/Plug-ins/metal.plugin/Contents/Resources"
	$ vim ./default.metal

### Build

	$ xcrun -sdk macosx metal -c default.metal -o default.air; xcrun -sdk macosx metallib default.air -o default.metallib

### Run

`Filter` > `mizt` > `metal`

### Reference

[minimum_ps_plugin](https://github.com/delphinus1024/minimum_ps_plugin)
