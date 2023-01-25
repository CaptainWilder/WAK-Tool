import subprocess
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
import configparser

# Read the config.ini file
config = configparser.ConfigParser()
config.read('config.ini')
SLACK_TOKEN = config['DEFAULT']['SLACK_TOKEN']
path_to_poke_sh = config['DEFAULT']['path_to_poke_sh']
client = WebClient(token=SLACK_TOKEN)

def poke_lookup(domain):
    try:
        result = subprocess.run([path_to_poke_sh, domain], capture_output=True)
        return result.stdout.decode()
    except Exception as e:
        return f"Error running poke.sh script for {domain}:\n{e}"

def handle_message(event):
    if "text" in event and "poke" in event["text"]:
        domain = event["text"].split("poke")[1].strip()
        response = poke_lookup(domain)
        channel = event["channel"]
        try:
            client.chat_postMessage(channel=channel, text=response)
        except SlackApiError as e:
            print("Error sending message: {}".format(e))

if __name__ == "__main__":
    rtm_client = RTMClient(token=SLACK_TOKEN, run_async=True, auto_reconnect=True)
    rtm_client.start()
