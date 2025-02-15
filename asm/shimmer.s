*
* Shimmer, 135 color SHR image viewer
*

*
* This is called shimmer because it will page flip 2 SHR images as quickly as
* as video interface on the machine allows
*

*
* We display as 128x100 pixel image, which is capable of up to 135 unique
* colors, all colors available on all lines, cheating our way past the 16
* colors per line limitation, by using persistence of vision to mix colors
*

*
* Prepare a 16 color $C1 Image, where
*
*     128x100 page 1 is on the upper left
*     128x100 page 1 is placed vertically below
*

        dsk shimmer.l


shimmer ent


