#!/bin/sh

# Usage: ./build_unix.sh [-hardiecs]
#  -h Show this info"
#  -a  Build all (deps, headers, examples)"
#  -r  Build release (DEFAULT, optimizations, -O2)"
#  -d  Build debug (-g, no optimmizations)"
#  -i  Build include headers"
#  -e  Build examples"
#  -c  Build clean (remove previous binarys / builds)"
#  -s  Build static library"
#  -n  Don't rebuild dependencies
#  -x  Don't build astera
#  -q  Quiet output
#  -qq Really quiet output

# NOTE: This build script is still a work in progress
# If you have any feature requests / ideas feel free to
# open an issue in github

# This function is to build up any files generated by the
# build process
build_cleanup() {
  current_dir=$PWD
  cd "$1"

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "CLEANUP: Starting"
  fi

  # Remove any precompiled libraries
  if [ -d "lib/" ]; then
    if [ -z "$QUIET" ]; then
      echo "CLEANUP: Removing lib folder."
    fi
    # Remove any old GLFW Precompiles
    rm -f "lib/libglfw.so" "lib/libglfw.so.3" "lib/libglfw.so.3.4"
    # Remove any old OpenAL-Soft Precompiles
    rm -f "lib/libopenal.so" "lib/libopenal.so.1" "lib/openal.so.19.1"

    # Remove any old Astera builds
    rm -f "lib/libastera.so"

    # If the lib folder is empty, remove it.
    if [ -s "$(ls lib)" ]; then
      rm -rf lib/
    fi
  fi

  # Remove any old dependency builds
  if [ -d "dep/glfw/build" ]; then
    if [ -z "$QUIET" ]; then
      echo "CLEANUP: Removing GLFW Build."
    fi
    rm -rf "dep/glfw/build"
  fi
  if [ -d "dep/openal-soft/build" ]; then
    if [ -z "$QUIET" ]; then
      echo "CLEANUP: Removing OpenAL-Soft Build."
    fi
    rm -rf "dep/openal-soft/build"
  fi

  # TODO remove this
  if [ -f "astera" ]; then 
    if [ -z "$QUIET" ]; then
      echo "CLEANUP: Removing astera executable."
    fi
    rm -f "astera"
  fi

  # Clean up the include directories
  if [ -d "include" ]; then
    # If the astera headers exist, then remove them
    if [ -d "include/astera" ]; then
      if [ -z "$QUIET" ]; then
        echo "CLEANUP: Removing astera headers"
      fi
      rm -rf include/astera
    fi

    # Check if the include folder is empty, if so, remove it.
    if [ -z "$(ls -A include)" ]; then
      if [ -z "$QUIET" ]; then
        echo "CLEANUP: Include folder is empty, removing it."
      fi 
      rm -rf include
    fi
  fi

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "CLEANUP: Complete"
  fi


  # Move back to the previous location
  cd "$current_dir"
}

# This function is to build the "include" headers
# used for external projects
build_include() {
  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "BUILD INCLUDE: Starting"
  fi

  if [ ! -d "$1/include" ]; then
    if [ -z "$QUIET" ]; then
      echo "BUILD INCLUDE: Created include folder at $1/include."
    fi
     mkdir "$1/include"
  fi

  # Create the astera include folder
  if [ ! -d "$1/include/astera" ]; then
      mkdir "$1/include/astera"
  fi

  if [ -z "$QUIET" ]; then
    echo "BUILD INCLUDE: copying astera headers."
  fi
  cp -r "$1"/src/*.h "$1"/include/astera/ 

  # Copy over GLFW's headers
  if [ -d "$1"/dep/glfw ]; then
    if [ -z "$QUIET" ]; then
     echo "BUILD INCLUDE: copying GLFW headers."
    fi

    cp -r "$1"/dep/glfw/include/* "$1"/include/
  fi  


  # Copy over OpenAL-Soft's headers
  if [ -d "$1"/dep/openal-soft ]; then
    if [ -z "$QUIET" ]; then
     echo "BUILD INCLUDE: copying OpenAL-Soft headers."
    fi

    cp -r "$1"/dep/openal-soft/include/* "$1"/include/
  fi  

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "BUILD INCLUDE: Complete"
  fi

}

# This function is to build the cmake headers
# and the binaries for GLFW
build_glfw() {
  # Record the previous location
  current_dir=$PWD

  # Move into the GLFW Directory for simplicity
  cd "$1"/dep/glfw

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "GLFW BUILD: Starting"
  fi

  # Check for required libraries even if not requesting rebuild
  if [ -n "$NO_REBUILD" ]; then
    # If the libraries already exist, there's no need to rebuild
    if [ -f "$1"/lib/libglfw.so ] && [ -f "$1"/lib/libglfw.so.3 ] && [ -f "$1"/lib/libglfw.so.3.4 ]; then
      if [ -z "$QUIET" ]; then
        echo "GLFW BUILD: NO_REBUILD Enabled and glfw libraries already exist."
      fi

      if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
        echo "GLFW BUILD: Pass"
      fi

      return
    else 
      # Check if an old version still exists
      if [ -f build/src/libglfw.so ] && [ -f build/src/libglfw.so.3 ] && [ -f build/src/libglfw.so.3.4 ]; then
        if [ -z "$QUIET" ]; then
          echo "GLFW BUILD: Copying previously compiled library to lib folder."
        fi
        cp build/src/libglfw.so "$1"/lib
        cp build/src/libglfw.so.3 "$1"/lib
        cp build/src/libglfw.so.3.4 "$1"/lib

        if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
          echo "GLFW BUILD: Pass"
        fi

        return
      fi
    fi
  fi

  # Check for an old build, if it exists and we want to rebuild
  # rebuild it
  if [ -d "build" ] && [ -z "$NO_REBUILD" ]; then 
    if [ -z "$QUIET" ]; then
      echo "GLFW BUILD: Removing old GLFW Build."
    fi
    rm -rf build
  fi

  mkdir -p build
  cd build

  # Generate the makefiles
  if [ -z "$QUIET" ]; then
    echo "GLFW BUILD: Building Makefile."
    cmake ../ -G "Unix Makefiles"
  else 
    cmake ../ -G "Unix Makefiles" >> /dev/null 2>&1
  fi

  # Compile the library
  if [ -z "$QUIET" ]; then
    echo "GLFW BUILD: Compiling Library"
    make
  else
    make >> /dev/null 2>&1
  fi

  # Make sure the lib folder exists
  if [ ! -d "$1/lib/" ]; then
    if [ -z "$QUIET" ]; then
      echo "GLFW BUILD: Creating lib folder at $1/lib/."
    fi
    mkdir "$1"/lib
  fi

  # Copy built libraries out to library folder
  if [ -z "$QUIET" ]; then
    echo "GLFW BUILD: Copying GLFW Shared Libraries to $1/lib/."
  fi

  cp src/libglfw.so "$1"/lib/
  cp src/libglfw.so.3 "$1"/lib/
  cp src/libglfw.so.3.4 "$1"/lib/

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "GLFW BUILD: Complete"
  fi
  # Return to the previous location
  cd "$current_dir"
}

# Build the OpenAL-Soft Dependency
build_al() {
  # Record the previous location
  current_dir=$PWD

  # Move into the GLFW Directory for simplicity
  cd "$1"/dep/openal-soft

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "OPENAL BUILD: Starting"
  fi

  # Check for required libraries even if not requesting rebuild
  if [ -n "$NO_REBUILD" ]; then
    # If the libraries already exist, there's no need to rebuild
    if [ -f "$1"/lib/libopenal.so ] && [ -f "$1"/lib/libopenal.so.1 ] && [ -f "$1"/lib/libopenal.so.1.19.1 ]; then
      if [ -z "$QUIET" ]; then
        echo "OPENAL BUILD: NO_REBUILD Enabled and OpenAL libraries already exist."
      fi

      if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
        echo "OPENAL BUILD: Pass"
      fi

      return
    else 
      # Check if an old version still exists
      if [ -f build/libopenal.so ] && [ -f build/libopenal.so.1 ] && [ -f build/libopenal.so.1.19.1 ]; then
        if [ -z "$QUIET" ]; then
          echo "OPENAL BUILD: Copying previously compiled library to lib folder."
        fi
        cp build/libopenal.so "$1"/lib
        cp build/libopenal.so.1 "$1"/lib
        cp build/libopenal.so.1.19.1 "$1"/lib

        if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
          echo "OPENAL BUILD: Pass"
        fi

        return
      fi
    fi
  fi

  # Check for an old build, if it exists and we want to rebuild
  # rebuild it
  if [ -d "build" ] && [ -z "$NO_REBUILD" ]; then 
    if [ -z "$QUIET" ]; then
      echo "OPENAL BUILD: Removing old OpenAL Build."
    fi
    rm -rf build
  fi

  # Create the build directory if needed
  mkdir -p build

  # Move into the build folder to isolate files
  cd build

  # Generate the makefiles
  if [ -z "$QUIET" ]; then
    echo "OPENAL BUILD: Building Makefile."
    cmake ../ -G "Unix Makefiles"
  else 
    cmake ../ -G "Unix Makefiles" >> /dev/null 2>&1
  fi

  # Compile the library
  if [ -z "$QUIET" ]; then
    echo "OPENAL BUILD: Compiling Library"
    make
  else
    make >> /dev/null 2>&1
  fi

  # Make sure the lib folder exists
  if [ ! -d "$1/lib/" ]; then
    if [ -z "$QUIET" ]; then
      echo "OPENAL BUILD: Creating lib folder at $1/lib/."
    fi
    mkdir "$1"/lib
  fi

  # Copy built libraries out to library folder
  if [ -z "$QUIET" ]; then
    echo "OPENAL BUILD: Copying OpenAL Shared Libraries to $1/lib/."
  fi

  cp libopenal.so "$1"/lib
  cp libopenal.so.1 "$1"/lib
  cp libopenal.so.1.19.1 "$1"/lib

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "OPENAL BUILD: Complete"
  fi

  # Return to the previous location
  cd "$current_dir"
}

# Build individual example
build_example() {
  echo "Building example $2."
}

# Build all of the examples
 build_examples() {
  if [ -z "$REALLY_QUIET" ] && [ -n "$QUIET" ]; then
    echo "EXAMPLES BUILD: Starting"
  fi
  # 
  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "EXAMPLES BUILD: Complete"
  fi
 }

# Stop if something fails
set -e

# Parse thru all the options
while getopts ":hardniecsxqq" opt; do
  case $opt in
    h)
      echo "Usage ./build_unix.sh [-hardiecs]"
      echo "-h  Show this info"
      echo "-a  Build all (deps, headers, examples)"
      echo "-r  Build release (DEFAULT, optimizations, -O2)"
      echo "-d  Build debug (-g, no optimmizations)"
      echo "-i  Build include headers"
      echo "-e  Build examples"
      echo "-c  Build clean (remove previous binarys / builds)"
      echo "-s  Build static library"
      echo "-n  Don't rebuild dependencies"
      echo "-x  Don't build astera"
      echo "-q  Quiet"
      echo "-qq Really Quiet"
      exit 0
      ;;
    a)
      BUILD_ALL="1"
      ;;
    r)
      BUILD_RELEASE="1"
      ;;
    d)
      BUILD_DEBUG="1"
      ;;
    i)
      BUILD_INCLUDE="1"
      ;;
    e)
      BUILD_EXAMPLES="1"
      ;;
    c)
      BUILD_CLEAN="1"
      ;;
    s)
      BUILD_STATIC="1"
      ;;
    x)
      NO_ASTERA="1"
      ;;
    q)
      if [ -n "$QUIET" ]; then
        REALLY_QUIET="1"
      else 
        QUIET="1"
      fi
      ;;
    n)
      NO_REBUILD="1"
      ;;
    \?)
      echo "Invalid option passed: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Get the directory above tools
ROOT_DIR="${PWD}"
SOURCES="$ROOT_DIR/src/*.c"

# Check if the clean flag was passed
if [ -n "$BUILD_CLEAN" ]; then
  if [ -z "$REALLY_QUIET" ]; then
    echo "Build clean selected."
  fi

  build_cleanup "$ROOT_DIR"

  if [ -z "$REALLY_QUIET" ]; then
    echo "Cleanup complete."
  fi

  exit 0
fi

# Check if we should build the dependencies as well
if [ -n "$BUILD_ALL" ]; then
  if [ -z "$REALLY_QUIET" ]; then
    echo "Build all selected."
  fi

  build_include "$ROOT_DIR"
  build_glfw "$ROOT_DIR"
  build_al "$ROOT_DIR"
elif [ -n "$BUILD_INCLUDE" ]; then
  build_include "$ROOT_DIR"
fi


if [ -z "$CC" ]; then
  if [ "$(command -v clang)" = 2 ]; then
    if [ "$(command -v gcc)" = 2 ]; then
      exit
    else
      CC=gcc
    fi
  else
    CC=clang
  fi
else
  echo "CC Override, using compiler: $CC."
fi

if [ -z "$CC_FLAGS" ]; then
  if [ -n "$BUILD_DEBUG" ]; then
    if [ -z "$QUIET" ]; then
      echo "ASTERA BUILD: Building for Debug."
    fi
    CC_FLAGS="-std=c99 -w -g"
  elif [ -n "$BUILD_RELEASE" ]; then
    if [ -z "$QUIET" ]; then
      echo "ASTERA BUILD: Building for Release."
    fi
    CC_FLAGS="-std=c99 -w -O2"
  else
    if [ -z "$QUIET" ]; then
      echo "ASTERA BUILD: Building normally."
    fi
    CC_FLAGS="-std=c99 -w" 
  fi
else # Check if there are already soem CC_FLAGS passed, if so, append to them
  if [ -n "$BUILD_DEBUG" ]; then
    if [ -z "$QUIET" ]; then
      echo "ASTERA BUILD: Building for Debug."
    fi
    CC_FLAGS="${CC_FLAGS} -std=c99 -w -g"
  elif [ -n "$BUILD_RELEASE" ]; then
    if [ -z "$QUIET" ]; then
      echo "ASTERA BUILD: Building for Release."
    fi
    CC_FLAGS="${CC_FLAGS} -std=c99 -w -O2"
  else
    if [ -z "$QUIET" ]; then
      echo "ASTERA BUILD: Building normally"
    fi
    CC_FLAGS="${CC_FLAGS} -std=c99 -w"
  fi
fi

if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$ROOT_DIR/lib/"
fi

if [ -z "$UNAME" ]; then
  UNAME=$(uname)
fi

if [ -z "$LD_FLAGS" ]; then
  LD_FLAGS="-I$ROOT_DIR/dep/ -I$ROOT_DIR/dep/glfw/include -I$ROOT_DIR/dep/openal-soft/include -L$ROOT_DIR/lib/ -Wl,-rpath,lib/ -lglfw -lGL -lopenal -lm"
fi

if [ "$UNAME" = "Linux" ]; then
  CC_FLAGS="${CC_FLAGS} -D Linux"
elif [ "$UNAME" = "FreeBSD" ]; then
  CC_FLAGS="${CC_FLAGS} -D FreeBSD"
elif [ "$UNAME" = "NetBSD" ]; then
  CC_FLAGS="${CC_FLAGS} -D NetBSD"
elif [ "$UNAME" = "OpenBSD" ]; then
  CC_FLAGS="${CC_FLAGS} -D OpenBSD"
elif [ "$UNAME" = "Darwin" ]; then
  CC_FLAGS="${CC_FLAGS} -D OSX"
fi

# Check if we're gonna build the astera library
if [ -z "$NO_ASTERA" ]; then
  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "ASTERA BUILD: Starting"
  fi

  # If we're not compiling for Mac OSX
  if [ ! "$UNAME" = "Darwin" ]; then
    # TODO Static Build Path
    if [ -n "$BUILD_STATIC" ]; then
      if [ -z "$QUIET" ]; then
        echo "ASTERA BUILD: Building static."
      fi
      # Static build goes here
    else
      if [ -z "$QUIET" ]; then
        echo "$CC $SOURCES $CC_FLAGS $LD_FLAGS -o astera"
      fi
      $CC $SOURCES $CC_FLAGS $LD_FLAGS -o astera 
    fi
  fi

  if [ -n "$QUIET" ] && [ -z "$REALLY_QUIET" ]; then
    echo "ASTERA BUILD: Complete"
  fi
fi

# Build all the examples
if [ -n "$BUILD_ALL" ] || [ -n "$BUILD_EXAMPLES" ]; then 
  # TODO Examples Build implementation
  build_examples "$ROOT_DIR"
fi
