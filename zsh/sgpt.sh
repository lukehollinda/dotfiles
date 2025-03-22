#! /bin/bash

# Depends on lm-stidio/lms
# lms server start
sgpt () {

	code=false
	while [ $# -ge 1 ]; do
		case "$1" in
			-m|--message)
				usermessage="$2"
				shift
				;;
			-c|--code)
				code=true
				;;
			-h)
				echo "Display some help"
				exit 0
				;;
		esac

		shift
	done

	if [[ -z $usermessage ]]; then
		echo "Please povide a prompt"
		exit 0
	fi

	if [[ $code == "true" ]]; then
		usermessage="Please only respond with example code. No discussion or introduction$usermessage"
	fi

	response=$(curl http://localhost:1234/v1/chat/completions -s \
		-H "Content-Type: application/json" \
		-d '{
			"model": "mlx-community/Llama-3.2-3B-Instruct-4bit",
			"messages": [{"role": "user", "content": "'"$usermessage"'"}],
			"temperature": 0.7
		}' | jq '.choices[0].message.content' )

	echo $response
}

