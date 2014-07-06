Script to build ZU kernels

Usage: ./build-kernel.sh [OPTIONS]
  -d   Device to build for (default=togari)
  -f   File system to use, either ext4 or f2fs (default=ext4)
  -k   Kernel to build, cm/bp/dt2w_cm/dt2w_bp (default=bp)
  -h   Show this help
  -l   Sync local only
  -w   Enable DT2W