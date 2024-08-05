#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
for cmd in yt-dlp ffmpeg fzf; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed. Please install it."
        exit 1
    fi
done

# Define paths
desktop_path=$(eval echo ~$USER/Desktop)  # Expand ~ to full path
home_directory=$(eval echo ~$USER)        # Expand ~ to full path

# Function to filter files, excluding hidden ones and handling permissions
filter_files() {
    find "$home_directory" -type f ! -path '*/\.*' 2>/dev/null |
    sed "s|$home_directory|~|" |
    sed "s|$desktop_path/||" |
    fzf --prompt="$1" --height=10 --border
}

# Function to convert songs to video with waveform visualizer
convert_song_with_waveform() {
    echo "Enter the path to the song file:"
    local song_file
    song_file=$(filter_files "Song file: ") || { echo "Failed to select song file. Exiting."; exit 1; }
    song_file=$(eval echo "$song_file")  # Expand ~ to full path

    # List of waveform colors
    local color_options=("black" "red" "green" "blue" "yellow" "cyan" "magenta" "gray")

    echo "Select the waveform color:"
    local waveform_color
    waveform_color=$(printf "%s\n" "${color_options[@]}" | fzf --prompt="Waveform color: " --height=10 --border) || { echo "Failed to select waveform color. Exiting."; exit 1; }

    # Map "black" to "white" internally
    if [ "$waveform_color" = "black" ]; then
        waveform_color="white"
    fi

    echo "Enter the output video filename (without extension):"
    local output_filename
    read -r output_filename || { echo "Failed to enter output filename. Exiting."; exit 1; }
    local output_video="$desktop_path/$output_filename.avi"

    echo "Converting song to video with waveform visualizer..."
    
    if ffmpeg -i "$song_file" -filter_complex "[0:a]showwaves=s=480x270:mode=cline:colors=$waveform_color[v];[0:a]aformat=channel_layouts=stereo[a]" -map "[v]" -map "[a]" -c:v libxvid -b:v 1000k -qscale:v 3 -c:a mp2 -b:a 192k "$output_video"; then
        echo "Song conversion complete. The output video is saved at $output_video"
    else
        echo "Error: Conversion failed. Please check the file paths and parameters."
    fi
}

# Function to convert songs to video with embedded artwork
convert_song_with_artwork() {
    echo "Enter the path to the song file:"
    local song_file
    song_file=$(filter_files "Song file: ") || { echo "Failed to select song file. Exiting."; exit 1; }
    song_file=$(eval echo "$song_file")  # Expand ~ to full path

    echo "Enter the output video filename (without extension):"
    local output_filename
    read -r output_filename || { echo "Failed to enter output filename. Exiting."; exit 1; }
    local output_video="$desktop_path/$output_filename.avi"

    echo "Converting song to video with embedded artwork..."

    # Extract artwork
    artwork=$(ffmpeg -i "$song_file" -an -vcodec copy -f image2 -y artwork.png 2>/dev/null && echo "artwork.png" || echo "")

    if [ -f "$artwork" ]; then
        # Use artwork as video background with 270x270 resolution
        if ffmpeg -i "$song_file" -i "$artwork" -filter_complex "[1:v]scale=270:270,setsar=1[v];[0:a]aformat=channel_layouts=stereo[a]" -map "[v]" -map "[a]" -c:v libxvid -b:v 1000k -qscale:v 3 -c:a mp2 -b:a 192k "$output_video"; then
            echo "Song conversion complete. The output video is saved at $output_video"
        else
            echo "Error: Conversion failed. Please check the file paths and parameters."
        fi
        rm "$artwork"
    else
        echo "Error: Failed to extract artwork. Exiting."
    fi
}

# Function to download and convert YouTube videos
download_and_convert_youtube() {
    read -p "Enter the YouTube video URL: " youtube_url
    read -p "Enter the output video filename (without extension): " output_filename
    local output_video="$desktop_path/$output_filename.avi"

    echo "Downloading and converting YouTube video..."

    if yt-dlp -f bestvideo+bestaudio "$youtube_url" -o - | \
       ffmpeg -i pipe:0 -vf "scale=480:270,setsar=1:1" -vcodec libxvid -b:v 1000k -qscale:v 3 -acodec mp2 -b:a 192k "$output_video"; then
        echo "YouTube video conversion complete. The output video is saved at $output_video"
    else
        echo "Error: Conversion failed. Please check the URL and parameters."
    fi
}

# Function to convert a local video
convert_local_video() {
    echo "Enter the path to the input video:"
    local input_video
    input_video=$(filter_files "Input video: ") || { echo "Failed to select input video. Exiting."; exit 1; }
    input_video=$(eval echo "$input_video")  # Expand ~ to full path

    echo "Enter the output video filename (without extension):"
    local output_filename
    read -r output_filename || { echo "Failed to enter output filename. Exiting."; exit 1; }
    local output_video="$desktop_path/$output_filename.avi"

    echo "Converting local video..."

    if ffmpeg -i "$input_video" -vf "scale=480:270,setsar=1:1" -vcodec libxvid -b:v 1000k -qscale:v 3 -acodec mp2 -b:a 192k "$output_video"; then
        echo "Local video conversion complete. The output video is saved at $output_video"
    else
        echo "Error: Conversion failed. Please check the input file and parameters."
    fi
}

# Main menu
echo "Select the operation:"
echo "1. YouTube Video"
echo "2. Audio File"
echo "3. Video File"
read -p "Enter your choice (1, 2 or 3): " choice

case $choice in
    1)
        download_and_convert_youtube
        ;;
    2)
        echo "Select conversion type:"
        echo "1. With waveform visualizer"
        echo "2. With embedded artwork"
        read -p "Enter your choice (1 or 2): " sub_choice
        case $sub_choice in
            1)
                convert_song_with_waveform
                ;;
            2)
                convert_song_with_artwork
                ;;
            *)
                echo "Invalid choice. Exiting."
                ;;
        esac
        ;;
    3)
        convert_local_video
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac
