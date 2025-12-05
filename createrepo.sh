#!/bin/sh
echo -n "Please enter your gitHub username: "
read -s username
echo
echo -n "Please enter your TOKEN: "
read -s token
echo
USERNAME=$username
TOKEN=$token

read -p "Enter master branch name: " branch
read -p "Enter repo name: " repo
read -p "Private? (y/n) " my_bool 

if [ "$my_bool" = "y" ]; then
    bool=true
elif [ "$my_bool" = "n" ]; then
    bool=false
else
    echo "Invalid input"
    exit 1
fi

echo "Private = $bool"



mkdir "$repo"
cd "$repo"
curl -X POST -u "${USERNAME}:${TOKEN}" https://api.github.com/user/repos -d "{\"name\":\"$repo\",\"private\":$bool}"

git init
echo "Creating README.md" > README.md
git add README.md
git commit -m "Repo created"
git remote add origin git@github.com:$username/$repo.git
git branch -M $branch
git push -u origin $branch

curl -L -u "${USERNAME}:${TOKEN}" https://api.github.com/user/repos | jq -r '.[] .full_name'
