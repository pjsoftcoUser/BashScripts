#!/bin/bash
# Requirements: Linux bash/ImageMagick
# 17 1024X768 in 8 secs with 100 quality, 30000 around 4 hours

# You can edit these settings:

# Default source
default_src="3.txt";

# Default destination
default_dst="2";

# Output JPG quality: maximum is 100 (recommended)
default_qua="100"

# Minimum width to resize greater than that
default_min_width="400"

# Maximum width to resize greater than that
default_max_width="600"

function resize(){

  echo "Conversion started..."

  # Setup arguments/sharpen/unsharp/quality parameters
  local argument1="-filter sinc -define filter:support=5 -resize 800"
  local argument2="-filter sinc -resize 800 -unsharp 0x0.5+0.8"
  local sharpen="-sharpen 0x1"
  local quality="-quality ${qua}"
  local COUNTER=0
  local last_resized=""

  # to make the script read white spaces
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")

  while read line 
    do
      echo "Checking ${line}"

      # create line with %20 instead of space
      lineNoSpace=${line// /%20}
      
      # Detect source image width and height
      src_w=$(identify -format "%w" "${lineNoSpace}")

      # Go to the next iteration if error
      if [ $? != 0 ]; then
        echo "${line} not accessible, moving to errorLog.txt"
        echo $line >> $dst/errorLog.txt    
        continue
      fi

      src_h=$(identify -format "%h" "${lineNoSpace}")

      # If the image considered large
      if ((${src_w} > ${defMinWidth} && ${src_w} < ${defMaxWidth})); then
        echo "Qualified to be resized, dimentions: ${src_w} X ${src_h}"
        # Resize, sharpen
        echo "processing ${line}"

        # Creating the path
        local temp=${line}
        # Take the file name out
        local trimedPath=${temp%/*}
        # Take the http:// out
        local path=${trimedPath#*/}

        if [[ ! -e $dst${path} ]]; then
            echo "Creating path $dst$path"
            mkdir -p $dst${path}
        fi

        if [[ ! -e $dst${path}/large ]]; then
            mkdir $dst${path}/large
        fi

        if [[ ! -e $dst${path}/error ]]; then
            mkdir $dst${path}/error
        fi
        
        # Not using the arguments because it errors out when try to handle spaces in the entry name
        convert ${lineNoSpace} -filter sinc -define filter:support=5 -resize 800 $dst${path}/large/$(basename $line)

        # If the last command result has error
        if [ $? == 0 ]; then
          COUNTER=$((COUNTER+1))  
          echo "Conversion successful"
          echo ""
        else
          echo "Sending to error directory"
          cp ${line} $dst${path}/error/$(basename $line)
        fi
        last_resized=${line}
      fi
  done < ${src}

  # Set the IFS back to normal
  IFS=$SAVEIFS

  echo "Last resized image: ${last_resized}"
  echo "Number of files resized: ${COUNTER}"
}

# Ask for source image, or use default value
echo "Welcome, add a line to the beginning and end of text file to make sure they won't be skipped!"
echo "Enter source path text file (.txt)/Enter to keep default (${default_src}): "
read src
src=${src:-${default_src}}

# Ask for destination path, or use default value
echo "Enter destination path/Enter to keep default (${default_dst}):"
read dst
dst=${dst:-${default_dst}}

# Ask for Minimum Width, or use default value
echo "Enter Minimum Width (to resize between Minimum/Enter to keep default (${default_min_width}):"
read defMinWidth
defMinWidth=${defMinWidth:-${default_min_width}}

# Ask for Maximum Width, or use default value
echo "Enter Maximum Width (and Maximum/Enter to keep default (${default_max_width}):"
read defMaxWidth
defMaxWidth=${defMaxWidth:-${default_max_width}}

# Ask for quality, or use default value
echo "Enter quality/Enter to keep default (${default_qua}):"
read qua
qua=${qua:-${default_qua}}

# Create the destination path
if [[ ! -e $dst ]]; then
    echo "Making ${dst} Directory..."
    mkdir $dst
fi

# Call the resize function
  resize

# Done!
echo "Done!"