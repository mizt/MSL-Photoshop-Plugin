# MSL-Photoshop-Plugin

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

### Usage
	
	$ cp -R ./bin/metal.plugin "/Applications/Adobe Photoshop 2020/Plug-ins" 
   	$ open "/Applications/Adobe Photoshop 2020/Adobe Photoshop 2020.app"
	
`Filter` > `mizt` > `Metal`

### Edit

	$ cd "/Applications/Adobe Photoshop 2020/Plug-ins/Metal.plugin/Contents/Resources"
	$ vim ./default.metal

### Build

MTL\_LANGUAGE\_REVISION must be Metal2.1.

	$ xcrun -sdk macosx metal -c default.metal -o default.air; xcrun -sdk macosx metallib default.air -o default.metallib

### Run

`Filter` > `mizt` > `Metal`

### Reference

[minimum_ps_plugin](https://github.com/delphinus1024/minimum_ps_plugin)
