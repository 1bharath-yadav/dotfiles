#!/usr/bin/env bash


# Extract audio (opus) + embed thumbnail

alias ytda='yt-dlp --extract-audio --audio-format opus --embed-thumbnail'

# Download compressed audio for speech-to-text
alias ytdlca='yt-dlp --extract-audio --audio-format opus --embed-thumbnail --postprocessor-args "-c:a libopus -b:a 12k -ac 1 -application voip -vbr off -ar 8000 -cutoff 4000 -frame_duration 60 -compression_level 10"'

# Download subtitles (just the subtitle file)
alias ytdsub='yt-dlp --write-auto-sub --sub-lang en --skip-download'

# Download video with best quality, with codec‐preferred priority: av01 → vp9 → mp4/h264
alias ytdv='yt-dlp -f "bestvideo[vcodec^=av01]+bestaudio/bestvideo[vcodec^=vp9]+bestaudio/bestvideo[ext=mp4][vcodec^=avc]+bestaudio/best" --merge-output-format mkv'






