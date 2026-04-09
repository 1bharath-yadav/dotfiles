#!/usr/bin/env bash

if command -v 'gdate' >/dev/null; then

  # Strip directory and suffix from filenames.
  alias basename=basename

  # Copy files and directories.
  alias cp=cp

  # Strip non-directory suffix from filenames.
  alias dirname=dirname

  # Create links between files.
  alias ln=ln

  # Print the name of the link.
  alias loname=loname

  # List directory contents.
  alias ls=ls

  # Create directories.
  alias mkdir=mkdir

  # Make named pipes (FIFOs).
  alias mkfifo=mkfifo

  # Make block or character special files.
  alias mknod=mknod

  # Move or rename files or directories.
  alias mv=mv

  # Check file name validity and portability.
  alias pathchk=pathchk

  # Print working directory name.
  alias pwd=pwd

  # Print resolved symbolic links or canonical file names.
  alias readlink=readlink

  # Print the resolved physical path of the specified path.
  alias realpath=realpath

  # Remove files or directories.
  alias rm=rm

  # Remove empty directories.
  alias rmdir=rmdir

  # Remove files or directories.
  alias unlink=unlink

  ## File content manipulation utilities

  # Pattern scanning and processing language.
  alias awk=awk

  # Concatenate and display files.
  alias cat=cat

  # Split a file into context-determined pieces.
  alias csplit=csplit

  # Remove sections from each line of files.
  alias cut=cut

  # Compare files line by line.
  alias diff=diff

  # Wrap each input line to fit in specified width.
  alias fold=fold

  # Print lines matching a pattern.
  alias grep=grep

  # Output the first part of files.
  alias head=head

  # Number lines of files.
  alias nl=nl

  # Merge lines of files.
  alias paste=paste

  # Apply a diff file to an original.
  alias patch=patch

  # ptx: Produce a permuted index of file contents.
  alias ptx=ptx

  # sed: Stream editor for filtering and transforming text.
  alias sed=sed

  # sort: Sort lines of text files.
  alias sort=sort

  # split: Split a file into pieces.
  alias split=split

  # tail: Output the last part of files.
  alias tail=tail

  # tr: Translate or delete characters.
  alias tr=tr

  ## File checksum and encryption utilities

  # Print or check BLAKE2 message digests.
  alias b2sum=b2sum

  # Print CRC checksum and byte counts.
  alias cksum=cksum

  # Print or check SHA1 message digests.
  alias sha1sum=sha1sum

  # Print or check SHA224 message digests.
  alias sha224sum=sha224sum

  # Print or check SHA256 message digests.
  alias sha256sum=sha256sum

  # Print or check SHA384 message digests.
  alias sha384sum=sha384sum

  # Print or check SHA512 message digests.
  alias sha512sum=sha512sum

  ## Other file utilities

  # Print or convert base32 data.
  alias base32=base32

  # Encode or decode base64 data.
  alias base64=base64

  # Encode or decode base64, base32,
  alias basenc=basenc

  webpall () {
    for file in *.png; do
        /c/Apps/libwebp/bin/cwebp -short -lossless -o "${file%.png}.webp" "$file"
    done
  }

  keyframes () {
    filename="${1%.*}"
    # Select all keyframes ensuring a max gap of 1 second. Fit to a 512x512 bounding box. Compress JPEG. Don't reduce quality (no-benefit)
    # ffmpeg -i "$1" -vf "select='key+isnan(prev_selected_t)+gte(t-prev_selected_t\,1)',showinfo,scale='if(gt(a,1),512,-2)':'if(gt(a,1),-2,512)'" -vsync vfr -compression_level 10 "$filename-%03d.jpg" 2>&1 | grep 'pts_time' | sed 's/.*pts_time:\([0-9.]*\).*/\1/' > "$filename-timestamps.txt"
    ffmpeg -i "$1" -vf "select='key',showinfo,scale='if(gt(a,1),512,-2)':'if(gt(a,1),-2,512)'" -vsync vfr -compression_level 10 "$filename-%03d.jpg" 2>&1 | grep 'pts_time' | sed 's/.*pts_time:\([0-9.]*\).*/\1/' > "$filename-timestamps.txt"
  }

fi
