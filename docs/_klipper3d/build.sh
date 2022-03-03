#!/bin/bash
# Modify the file structure before running mkdocs
# This is a make shift script before the current structure of
# Klipper-translations can be directly utilized by mkdocs

# Give up on building when language specific sites failed. Keep
# English site avaiable.
set -e

MKDOCS_DIR="docs/_klipper3d/"

# Prepare English Fallback
touch "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}base.yml" >> "${MKDOCS_DIR}en.yml"
# search must be insertede here to ensure it's placed in plugins
cat "${MKDOCS_DIR}search_en.yml" >> "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}extra.yml" >> "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}dir_en.yml" >> "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}nav_en.yml" >> "${MKDOCS_DIR}en.yml"
mkdir docs/en
mv docs/*.md docs/en/

# generate fall back files
mkdocs build -f docs/_klipper3d/en.yml

#fetch translations
git clone --depth 1 https://github.com/Klipper3d/klipper-translations

while IFS="," read dirname langname langdesc note; do
  new_local_dir="docs/${langname}"
  local_dir="klipper-translations/docs/locales/$dirname"
  mkdir $new_local_dir
  # move and rename markdown files
  echo "Moving $dirname to $langname"
  mv "$local_dir"/*.md "$new_local_dir"

  # manually replace index.md if a manual-index.md exist
  manual_index="${new_local_dir}manual-index.md"
  if [[ -f "$manual_index" ]];then
    mv "$manual_index" "${new_local_dir}/index.md"
    echo "replaced index.md with manual_index.md for $langname"
  else
      echo "Manually translated index file for $langname not found!"
  fi
  
  # Insert entries to extra.yml for language switching
  echo "      - name: ${langdesc}\n      link: /${langname}/\n      lang: ${langname}\n" >> "${MKDOCS_DIR}extra.yml"
done <  <(egrep -v '^ *(#|$)' ./klipper-translations/active_translations)

while IFS="," read dirname langname langdesc note; do
  # create language specific directory configurations

  touch "${langname}.yml"
  cat "${MKDOCS_DIR}base.yml" >> "${MKDOCS_DIR}${langname}.yml"
  # create language specific search configuration, must be after base.yml
  echo "  search:\n      lang: ${langname}\n" >> "${MKDOCS_DIR}${langname}.yml"
  # add directories
  echo "docs_dir: '../${langname}'\n" >> "${MKDOCS_DIR}${langname}.yml"
  echo "site_dir: '../../site/${langname}'\n" >> "${MKDOCS_DIR}${langname}.yml"
  
  # create language specific naviagtion table (TODO, reserved)
  cat "${MKDOCS_DIR}nav_en.yml" >> "${MKDOCS_DIR}${langname}.yml"
  # build sites
  mkdocs build -f "docs/_klipper3d/${langname}.yml"
done <  <(egrep -v '^ *(#|$)' ./klipper-translations/active_translations)

# remove fall back and rebuild with a correct extra.yml
cat "${MKDOCS_DIR}base.yml" > "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}search_en.yml" >> "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}extra.yml" >> "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}dir_en.yml" >> "${MKDOCS_DIR}en.yml"
cat "${MKDOCS_DIR}nav_en.yml" >> "${MKDOCS_DIR}en.yml"
rm -rf site/en
mkdocs build -f "docs/_klipper3d/en.yml"