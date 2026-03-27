from pathlib import Path


ROOT = Path("/opt/ric-plt-xapp-frame-py")

MODEL_FILES = [
    "ricxappframe/subsclient/models/action_definition.py",
    "ricxappframe/subsclient/models/action_to_be_setup.py",
    "ricxappframe/subsclient/models/actions_to_be_setup.py",
    "ricxappframe/subsclient/models/config_metadata.py",
    "ricxappframe/subsclient/models/event_trigger_definition.py",
    "ricxappframe/subsclient/models/subscription_data.py",
    "ricxappframe/subsclient/models/subscription_detail.py",
    "ricxappframe/subsclient/models/subscription_details_list.py",
    "ricxappframe/subsclient/models/subscription_instance.py",
    "ricxappframe/subsclient/models/subscription_list.py",
    "ricxappframe/subsclient/models/subscription_params.py",
    "ricxappframe/subsclient/models/subscription_params_client_endpoint.py",
    "ricxappframe/subsclient/models/subscription_params_e2_subscription_directives.py",
    "ricxappframe/subsclient/models/subscription_response.py",
    "ricxappframe/subsclient/models/subsequent_action.py",
    "ricxappframe/subsclient/models/x_app_config.py",
    "ricxappframe/subsclient/models/xapp_config_list.py",
]

MAPPING_BLOCK = """        for old_key, new_key in self.attribute_map.items():
            if old_key in result:
                result[new_key] = result.pop(old_key)

"""


def patch_model_file(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if "result[new_key] = result.pop(old_key)" in text:
        return

    marker = "\n        return result\n"
    if marker not in text:
        raise RuntimeError(f"Could not find return marker in {path}")

    text = text.replace(marker, f"\n{MAPPING_BLOCK}        return result\n", 1)
    path.write_text(text, encoding="utf-8")


def patch_subscribe_file(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    old = '            response = self.api.request(method="POST", url=self.uri, headers=None, body=subs_params.to_dict())\n'
    new = '            response = self.api.request(method="POST", url=self.uri + "/subscriptions", headers=None, body=subs_params.to_dict())\n'
    if new in text:
        return
    if old not in text:
        raise RuntimeError(f"Could not find POST request line in {path}")

    text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")


for relative_path in MODEL_FILES:
    patch_model_file(ROOT / relative_path)

patch_subscribe_file(ROOT / "ricxappframe/xapp_subscribe.py")
