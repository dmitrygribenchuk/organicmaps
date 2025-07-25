#!/usr/bin/env bash
set -euo pipefail

if ! command -v optipng &> /dev/null
then
    echo -e "\033[1;31moptipng could not be found"
    if [[ $OSTYPE == 'darwin'* ]]; then
       echo 'run command'
       echo 'brew install optipng'
       echo 'to install it'
       exit
    fi
    echo 'take a look to http://optipng.sourceforge.net/'
    exit
fi

# Prevent python from generating compiled *.pyc files
export PYTHONDONTWRITEBYTECODE=1

BINARY_NAME=skin_generator_tool
OMIM_PATH="${OMIM_PATH:-$(cd "$(dirname "$0")/../.."; pwd)}"
BUILD_DIR="$OMIM_PATH/build"
SKIN_GENERATOR="${SKIN_GENERATOR:-$BUILD_DIR/$BINARY_NAME}"
DATA_PATH="$OMIM_PATH/data"

# cmake rebuilds skin generator binary if necessary.
cmake -S "$OMIM_PATH" -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release -DSKIP_TESTS:bool=true
cmake --build "$BUILD_DIR" --target "$BINARY_NAME"


# Helper function to build skin
# Parameter $1 - style type (default)
# Parameter $2 - style name (light, dark, ...)
# Parameter $3 - resource name (mdpi, hdpi, ...)
# Parameter $4 - symbol size
# Parameter $5 - style suffix (none, _light, _dark)
# Parameter $6 - symbols folder (symbols)
# Parameter $7 - symbols suffix (none, -ad)
function BuildSkin() {
  styleType=$1
  styleName=$2
  resourceName=$3
  symbolSize=$4
  suffix=$5
  symbolsFolder=$6
  symbolsSuffix=${7-}

  echo "Building skin for $styleName/$resourceName"
  # Set environment
  STYLE_PATH="$DATA_PATH/styles/$styleType/$styleName"
  PNG_PATH="$STYLE_PATH/symbols$symbolsSuffix/png"
  rm -rf "$PNG_PATH" || true
  ln -s "$STYLE_PATH/$resourceName$symbolsSuffix" "$PNG_PATH"
  # Run skin generator
  "$SKIN_GENERATOR" --symbolWidth $symbolSize --symbolHeight $symbolSize --symbolsDir "$STYLE_PATH/$symbolsFolder" \
      --skinName "$DATA_PATH/symbols/$resourceName/$suffix/basic" --skinSuffix="$symbolsSuffix"
  # Reset environment
  rm -r "$PNG_PATH" || true
}

symbols_name=(6plus mdpi hdpi xhdpi xxhdpi xxxhdpi)

# Cleanup
rm -rf "$DATA_PATH"/symbols/*/*/symbols.*

# Build styles

BuildSkin default dark  mdpi    18 dark  symbols
BuildSkin default dark  hdpi    27 dark  symbols
BuildSkin default dark  xhdpi   36 dark  symbols
BuildSkin default dark  6plus   43 dark  symbols
BuildSkin default dark  xxhdpi  54 dark  symbols
BuildSkin default dark  xxxhdpi 64 dark  symbols

BuildSkin default light mdpi    18 light symbols
BuildSkin default light hdpi    27 light symbols
BuildSkin default light xhdpi   36 light symbols
BuildSkin default light 6plus   43 light symbols
BuildSkin default light xxhdpi  54 light symbols
BuildSkin default light xxxhdpi 64 light symbols

for i in ${symbols_name[*]}; do
  optipng -zc9 -zm8 -zs0 -f0 "$DATA_PATH"/symbols/"${i}"/light/symbols.png
  optipng -zc9 -zm8 -zs0 -f0 "$DATA_PATH"/symbols/"${i}"/dark/symbols.png
done

rm -rf "$DATA_PATH"/symbols/*/design/

for i in ${symbols_name[*]}; do
  cp -r "$DATA_PATH"/symbols/"${i}"/light/ "$DATA_PATH"/symbols/"${i}"/design/
done
