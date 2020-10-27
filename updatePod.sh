echo read -p "输入版本号:" version
git add .
git commit -m "${version}"
git push
git tag ${version}
git push --tags
pod repo push WTSpec WTPhotos.podspec --allow-warnings
