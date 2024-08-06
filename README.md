## About
This is a Linux script that can convert: Video files, Audio Files and YouTube Links.
The output of the conversion is an Xvid video file that is compatible with the Sony DVP-FX780 DVD Player.
This script is made specifically for use with USB drives and it therefore not tested with DVDs.
## Get started (Linux Desktop)
Disclaimer: the USB Drive must be formated as FAT32.
1. The script is in the list next to the README.md, you can click on it and download the file.
2. In a terminal, go to the directory where the script is downloaded. 
3. Allow it to run: `chmod +x Sony_DVP-FX780.sh`
4. Run it: `./Sony_DVP-FX780.sh`
The converted files are saved in the Desktop folder (**It must exist**).
## Get started (Termux)
Disclaimer: the USB Drive must be formated as FAT32.
You will also need an OTG adapter to plug the USB drive into the phone.
Update the termux Linux system `pkg update && pkg upgrade`
Make the **needed** Desktop folder: `mkdir Desktop`
Install dependencies: `pkg install python-pip ffmpeg fzf && pip install -U --no-deps yt-dlp`
Set up Android storage access to be able to access the media you want to convert.
`pkg install termux-api && termux-setup-storage`
Go to the directory: `cd Sony-DVP-FX780-Media-Converter`
Allow it to run: `chmod +x Sony_DVP-FX780.sh`
Get your media that you want to convert by copying it to the home folder of termux.
Then, run the script (you have to be in the git cloned folder): `./Sony_DVP-FX780.sh`
## YouTube Links
The script accepts both video and audio YouTube links but it is not intended for use with audio links as the music artwork will be stretched (this does not apply to music videos, and only applies to non 16:9 videos).
## Audio Files
The Audio Files convertion option has a submenu with 2 options
### Visualizer
A waveform visualizer That can be set to the following colors: gray, magenta, cyan, yellow, blue, green, red, black.
Uses a lot more storage.
### Artwork
Shows the artwork embedded in the audio file selected.
File size close to the original.
## Video Files
This convertion option also accepts mp3 files but trying to play them on the DVD Player will result in an error.
