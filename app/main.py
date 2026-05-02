import yaml
import os
import json
from google.cloud import pubsub_v1
from googleapiclient.discovery import build
from flask import Request

# Load config.yaml
with open("config.yaml") as f:
    config = yaml.safe_load(f)

# Initialize clients
youtube = build("youtube", "v3", developerKey=config["youtube_api_key"])
publisher = pubsub_v1.PublisherClient()

# Try to get project ID from env; fall back to explicit default for safety
PROJECT_ID = os.environ.get("GCP_PROJECT", "yt-comments-495004")
TOPIC_NAME = config["pubsub_topic"]
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_NAME)

print(f"[INIT] Using Project ID: {PROJECT_ID}")
print(f"[INIT] Using Topic: {TOPIC_NAME}")
print(f"[INIT] Full topic path: {topic_path}")

def main(request: Request):
    print("[INFO] YouTube comment ingestion started...")

    try:
        # Fetch latest comments for the configured channel
        request_youtube = youtube.commentThreads().list(
            part="snippet",
            allThreadsRelatedToChannelId=config["channel_id"],
            maxResults=config["max_results"]
        )
        response = request_youtube.execute()
        print(f"[INFO] Retrieved {len(response.get('items', []))} comments from YouTube API.")
    except Exception as e:
        print(f"[ERROR] Failed to fetch YouTube comments: {e}")
        return f"Error fetching comments: {e}", 500

    published_count = 0
    for item in response.get("items", []):
        try:
            comment_text = item["snippet"]["topLevelComment"]["snippet"]["textDisplay"]
            comment_id = item["snippet"]["topLevelComment"]["id"]
            message_json = json.dumps({
                "id": comment_id,
                "comment": comment_text
            })

            print(f"[PUBLISH] Sending comment ID {comment_id[:10]}...")  # show short prefix for readability
            future = publisher.publish(topic_path, message_json.encode("utf-8"))
            future.result()  # Wait for confirmation
            published_count += 1

        except Exception as e:
            print(f"[ERROR] Failed to publish comment: {e}")

    print(f"[SUCCESS] Published {published_count} comments to Pub/Sub topic: {topic_path}")
    return f"Comments pushed to Pub/Sub ({published_count} messages).", 200