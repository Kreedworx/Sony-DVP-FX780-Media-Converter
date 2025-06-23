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
current_path=$(eval echo .)
home_directory=$(eval echo ~$USER)

# Function to filter files
filter_files() {
    find "$home_directory" -type f ! -path '*/\.*' 2>/dev/null |
    sed "s|$home_directory|~|" |
    sed "s|$current_path/||" |
    fzf --prompt="$1" --height=10 --border
}

# Select a folder and get matching files
select_files_in_directory() {
    local folder
    folder=$(find "$home_directory" -type d ! -path '*/\.*' 2>/dev/null | fzf --prompt="Select a directory: " --height=10 --border)
    [ -z "$folder" ] && return 1
    folder=$(eval echo "$folder")

    if [ -d "$folder" ]; then
        find "$folder" -maxdepth 1 -type f 2>/dev/null
    else
        echo "Invalid folder selected." >&2
        return 1
    fi
}

is_audio() {
    ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$1" 2>/dev/null | grep -q audio
}

is_video() {
    ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$1" 2>/dev/null | grep -q video
}

convert_song_with_waveform() {
    local song_file
    song_file=$(filter_files "Song file: ") || { echo "No file selected."; return; }
    song_file=$(eval echo "$song_file")

    local color_options=("black" "red" "green" "blue" "yellow" "cyan" "magenta" "gray")
    local waveform_color
    waveform_color=$(printf "%s\n" "${color_options[@]}" | fzf --prompt="Waveform color: " --height=10 --border) || return
    [ "$waveform_color" = "black" ] && waveform_color="white"

    read -r -p "Enter the output video filename (without extension): " output_filename || return
    local output_video="$current_path/$output_filename.avi"

    ffmpeg -i "$song_file" -filter_complex "[0:a]showwaves=s=480x270:mode=cline:colors=$waveform_color[v];[0:a]aformat=channel_layouts=stereo[a]" -map "[v]" -map "[a]" -c:v libxvid -b:v 1000k -qscale:v 3 -c:a mp2 -b:a 192k "$output_video"
    echo "Output saved to $output_video"
}

bulk_convert_waveform() {
    local color_options=("black" "red" "green" "blue" "yellow" "cyan" "magenta" "gray")
    local waveform_color
    waveform_color=$(printf "%s\n" "${color_options[@]}" | fzf --prompt="Waveform color: " --height=10 --border) || return
    [ "$waveform_color" = "black" ] && waveform_color="white"

    mapfile -t files < <(select_files_in_directory)
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found."
        return
    fi

    for song_file in "${files[@]}"; do
        is_audio "$song_file" || continue
        local base_name=$(basename "$song_file" | sed 's/\.[^.]*$//')
        local output_video="$current_path/${base_name}.avi"
        echo "Processing: $song_file"
        ffmpeg -y -i "$song_file" -filter_complex "[0:a]showwaves=s=480x270:mode=cline:colors=$waveform_color[v];[0:a]aformat=channel_layouts=stereo[a]" -map "[v]" -map "[a]" -c:v libxvid -b:v 1000k -qscale:v 3 -c:a mp2 -b:a 192k "$output_video"
    done
    echo "Batch waveform conversion done."
}

convert_song_with_artwork() {
    local song_file
    song_file=$(filter_files "Song file: ") || return
    song_file=$(eval echo "$song_file")

    read -r -p "Enter output video filename (without extension): " output_filename || return
    local output_video="$current_path/$output_filename.avi"

    local artwork
    artwork=$(ffmpeg -i "$song_file" -an -vcodec copy -f image2 -y artwork.png 2>/dev/null && echo "artwork.png" || echo "")

    if [ -f "$artwork" ]; then
        ffmpeg -i "$song_file" -i "$artwork" -filter_complex "[1:v]scale=270:270,setsar=1[v];[0:a]aformat=channel_layouts=stereo[a]" -map "[v]" -map "[a]" -c:v libxvid -b:v 1000k -qscale:v 3 -c:a mp2 -b:a 192k "$output_video"
        rm "$artwork"
        echo "Output saved to $output_video"
    else
        echo "Artwork extraction failed."
    fi
}

bulk_convert_artwork() {
    mapfile -t files < <(select_files_in_directory)
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found."
        return
    fi

    for song_file in "${files[@]}"; do
        is_audio "$song_file" || continue
        local base_name=$(basename "$song_file" | sed 's/\.[^.]*$//')
        local output_video="$current_path/${base_name}.avi"
        local artwork
        artwork=$(ffmpeg -i "$song_file" -an -vcodec copy -f image2 -y artwork.png 2>/dev/null && echo "artwork.png" || echo "")

        if [ -f "$artwork" ]; then
            ffmpeg -i "$song_file" -i "$artwork" -filter_complex "[1:v]scale=270:270,setsar=1[v];[0:a]aformat=channel_layouts=stereo[a]" -map "[v]" -map "[a]" -c:v libxvid -b:v 1000k -qscale:v 3 -c:a mp2 -b:a 192k "$output_video"
            rm "$artwork"
            echo "Output saved to $output_video"
        else
            echo "Artwork extraction failed for $song_file"
        fi
    done
    echo "Batch artwork conversion done."
}

convert_local_video() {
    local input_video
    input_video=$(filter_files "Input video: ") || return
    input_video=$(eval echo "$input_video")

    read -r -p "Enter output video filename (without extension): " output_filename || return
    local output_video="$current_path/$output_filename.avi"

    ffmpeg -i "$input_video" -vf "scale=480:270,setsar=1:1" -vcodec libxvid -b:v 1000k -qscale:v 3 -acodec mp2 -b:a 192k "$output_video"
    echo "Output saved to $output_video"
}

bulk_convert_video() {
    mapfile -t files < <(select_files_in_directory)
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found."
        return
    fi

    for input_video in "${files[@]}"; do
        is_video "$input_video" || continue
        local base_name=$(basename "$input_video" | sed 's/\.[^.]*$//')
        local output_video="$current_path/${base_name}.avi"

        echo "Processing: $input_video"
        ffmpeg -y -i "$input_video" -vf "scale=480:270,setsar=1:1" -vcodec libxvid -b:v 1000k -qscale:v 3 -acodec mp2 -b:a 192k "$output_video"
    done
    echo "Batch video conversion done."
}

download_and_convert_youtube() {
    read -r -p "Enter the YouTube video URL: " youtube_url || return
    read -r -p "Enter output video filename (without extension): " output_filename || return
    local output_video="$current_path/$output_filename.avi"

    yt-dlp -f bestvideo+bestaudio "$youtube_url" -o - | \
    ffmpeg -i pipe:0 -vf "scale=480:270,setsar=1:1" -vcodec libxvid -b:v 1000k -qscale:v 3 -acodec mp2 -b:a 192k "$output_video"
    echo "Output saved to $output_video"
}

# Menu
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
        echo "1. Visualizer"
        echo "2. Artwork"
        read -p "Enter your choice (1 or 2): " sub_choice
        case $sub_choice in
            1)
                echo "Bulk process or single?"
                echo "1. Single"
                echo "2. Bulk"
                read -p "Enter choice: " waveform_mode
                case $waveform_mode in
                    1) convert_song_with_waveform ;;
                    2) bulk_convert_waveform ;;
                    *) echo "Invalid." ;;
                esac
                ;;
            2)
                echo "Bulk process or single?"
                echo "1. Single"
                echo "2. Bulk"
                read -p "Enter choice: " artwork_mode
                case $artwork_mode in
                    1) convert_song_with_artwork ;;
                    2) bulk_convert_artwork ;;
                    *) echo "Invalid." ;;
                esac
                ;;
            *)
                echo "Invalid choice. Exiting."
                ;;
        esac
        ;;
    3)
        echo "Bulk process or single?"
        echo "1. Single"
        echo "2. Bulk"
        read -p "Enter choice: " video_mode
        case $video_mode in
            1) convert_local_video ;;
            2) bulk_convert_video ;;
            *) echo "Invalid." ;;
        esac
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac
