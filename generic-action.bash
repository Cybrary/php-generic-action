#!/bin/bash
set -e
github_action_path=$(dirname "$0")
docker_tag=$(cat ./docker_tag)
echo "Docker tag: $docker_tag" >> output.log 2>&1

# command_string is passed directly to the docker executable. It includes the
# container name and version, and this script will build up the rest of the
# arguments according to the action's input values.
command_string=""

if [ -n "$ACTION_COMMAND" ]
then
	command_string="$ACTION_COMMAND"
fi

echo "Command: $command_string" >> output.log 2>&1


dockerKeys=()
while IFS= read -r line
do
	dockerKeys+=( $(echo "$line" | cut -f1 -d=) )
done <<<$(docker run --rm "${docker_tag}" env)

while IFS= read -r line
do
	key=$(echo "$line" | cut -f1 -d=)
	if printf '%s\n' "${dockerKeys[@]}" | grep -q -P "^${key}\$"
	then
    		echo "Skipping env variable $key" >> output.log
	else
		echo "$line" >> DOCKER_ENV
	fi
done <<<$(env)

echo "::set-output name=full_command::${command_string}"

docker run --rm \
	--volume "${GITHUB_WORKSPACE}":/app \
	--workdir /app \
	--env-file ./DOCKER_ENV \
	--network host \
	${docker_tag} ${command_string}
