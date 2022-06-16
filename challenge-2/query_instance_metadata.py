import requests
import json

def extract_json(url, path):
    result = {}
    for i in path:
        url_i = url + i
        r = requests.get(url_i)
        text = r.text
        if i[-1] == "/":
            values = r.text.splitlines()
            result[i[:-1]] = extract_json(url_i, values)
        elif is_valid(text):
            result[i] = json.loads(text)
        else:
            result[i] = text
    return result

def instance_metadata():
    result = extract_json('http://169.254.169.254/latest/', 'meta-data/')
    return result

def instance_metadata_json():
    md = instance_metadata()
    instance_metadata_json = json.dumps(md, indent=4, sort_keys=True)
    return instance_metadata_json

def is_valid(text):
    try:
        json.loads(text)
    except ValueError:
        return False
    return True

def extract_key(key, metadata):
    if hasattr(metadata, 'items'):
        for k, v in metadata.items():
            if k == key:
                yield v
            if isinstance(v, dict):
                for result in extract_key(key, v):
                    yield result
            elif isinstance(v, list):
                for d in v:
                    for result in extract_key(key, d):
                        yield result

def get_key(key):
    metadata = instance_metadata()
    return list(extract_key(key, metadata))

if __name__ == '__main__':
    key = input("Input the key: \n")
    print(get_key(key))  
    print(instance_metadata_json())