from bson import ObjectId
from datetime import datetime

def serialize_doc(doc):
    if doc is None:
        return None
    
    # Create a copy to avoid modifying original during iteration
    new_doc = {}
    for key, value in doc.items():
        if key == "_id":
            new_doc[key] = str(value)
        elif isinstance(value, ObjectId):
            new_doc[key] = str(value)
        elif isinstance(value, datetime):
            new_doc[key] = value.isoformat()
        elif isinstance(value, (list, tuple)):
            # Convert any ObjectIds/datetimes inside lists
            new_list = []
            for item in value:
                if isinstance(item, ObjectId):
                    new_list.append(str(item))
                elif isinstance(item, datetime):
                    new_list.append(item.isoformat())
                else:
                    new_list.append(item)
            new_doc[key] = new_list
        else:
            new_doc[key] = value
            
    return new_doc

def serialize_docs(docs):
    if not docs:
        return []
    return [serialize_doc(d) for d in docs]
