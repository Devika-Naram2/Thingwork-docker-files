#!/bin/bash

# Resolve each of the subdirectories under /@var_dirs@/ as environment variables,
# and copy the contents to the resolved location.
for var_dir in $(compgen -G "/@var_dirs@/*"); do
  var=$(basename "${var_dir}")
  eval resolved_dir="\${$var}"
  mkdir -p "${resolved_dir}"
  (cd "${var_dir}"
   xfiles=$(find "${var_dir}" -name '*.sh')
   for f in ${xfiles}; do
     echo "Adding execute permission to ${f}"
     chmod +x "${f}"
   done
  )
  for f in $(compgen -G "${var_dir}/*"); do
    cp -vr "${f}" "${resolved_dir}"
  done
done
