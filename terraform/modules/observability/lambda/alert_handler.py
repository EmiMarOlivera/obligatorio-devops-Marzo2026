import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    for record in event.get("Records", []):
        sns_message = json.loads(record["Sns"]["Message"])

        alarm_name = sns_message.get("AlarmName", "Unknown")
        new_state = sns_message.get("NewStateValue", "Unknown")
        reason = sns_message.get("NewStateReason", "")
        region = sns_message.get("Region", "")

        if new_state == "ALARM":
            logger.warning(
                f"[ALERTA] {alarm_name} | Estado: {new_state} | Region: {region} | Motivo: {reason}"
            )
        elif new_state == "OK":
            logger.info(
                f"[RESUELTA] {alarm_name} | Estado: {new_state} | Region: {region}"
            )
        else:
            logger.info(
                f"[INFO] {alarm_name} | Estado: {new_state}"
            )

    return {"statusCode": 200}
