If you are using the **python-letta SDK**, then no—you do **not** use a MemFS CRUD API from that SDK, because the public Python SDK docs expose memory **blocks** and the **Filesystem API/folders/files**, but not Letta Code’s git-backed MemFS CRUD surface as first-class SDK methods.  So with the SDK, the manageable memory-related surfaces are mainly: [letta](https://www.letta.com/blog/memory-blocks)

- `client.blocks.*` for global block CRUD. [docs.letta](https://docs.letta.com/api/python/resources/blocks/methods/list)
- `client.agents.blocks.*` for agent-scoped block read/update. [docs.letta](https://docs.letta.com/api/python/resources/agents/subresources/blocks/)
- `client.folders.*`, `client.folders.files.*`, `client.agents.folders.*`, and `client.agents.files.*` for filesystem-style file access. [docs.letta](https://docs.letta.com/tutorials/shared-memory-blocks/)

## What the SDK gives you

The Python SDK documentation shows block creation, block retrieval, block update, shared block attachment, folder creation, file upload, folder attach, and agent file opening.  By contrast, Letta Code memory docs describe MemFS as the newer git-backed markdown memory system, but that is documented as a Letta Code behavior rather than a Python SDK CRUD namespace like `client.memfs.*`. [docs.letta](https://docs.letta.com/letta-code/memory/)

So if you want pure SDK code snippets today, the practical answer is:

- Use **folders/files** for filesystem-like attached data. [docs.letta](https://docs.letta.com/guides/core-concepts/filesystem/)

## Filesystem operations

If by “filesystem” you mean the Letta **Filesystem API** exposed in Python, these are the documented SDK snippets. [docs.letta](https://docs.letta.com/guides/core-concepts/filesystem/)

### 11. Create a folder
```python
folder = client.folders.create(
    name="project_docs",
)
print(folder.id)
```
The SDK docs show folder creation as the first step before file upload. [docs.letta](https://docs.letta.com/guides/core-concepts/filesystem/)

### 12. Upload a file into a folder
```python
with open("requirements.md", "rb") as f:
    uploaded_file = client.folders.files.upload(
        file=f,
        folder_id=folder.id,
    )

print(uploaded_file.id)
```
The filesystem guide says uploading creates an async processing job that chunks and embeds the file. [docs.letta](https://docs.letta.com/guides/core-concepts/filesystem/)

### 13. List folders
```python
folders = client.folders.list()

for f in folders:
    print(f.id, f.name)
```
The filesystem guide explicitly includes listing available folders. [docs.letta](https://docs.letta.com/guides/core-concepts/filesystem/)

### 14. Attach a folder to an agent
```python
client.agents.folders.attach(
    agent_id=agent.id,
    folder_id=folder.id,
)
```
The SDK docs show this exact folder-to-agent attach flow. [docs.letta](https://docs.letta.com/guides/core-concepts/filesystem/)

### 15. Open a file for an agent
```python
closed_files = client.agents.files.open(
    agent_id=agent.id,
    file_id=uploaded_file.id,
)
print(closed_files)
```
The documented behavior is that the file is marked open in the agent’s file state and may cause LRU eviction of other open files. [docs.letta](https://docs.letta.com/tutorials/shared-memory-blocks/)

## Useful SDK options

The Python SDK docs also document several cross-cutting options you can use with these operations. [letta](https://www.letta.com/blog/memory-blocks)

### 16. Error handling
```python
from letta_client.core.api_error import ApiError

try:
    block = client.agents.blocks.retrieve(
        agent_id=agent.id,
        block_label="human",
    )
except ApiError as e:
    print(e.status_code)
    print(e.message)
    print(e.body)
```
The SDK docs explicitly show `ApiError` handling with `status_code`, `message`, and `body`. [letta](https://www.letta.com/blog/memory-blocks)

### 17. Per-request retries
```python
agent = client.agents.create(
    model="openai/gpt-4o-mini",
    embedding="openai/text-embedding-3-small",
    memory_blocks=[{"label": "persona", "value": "Helpful assistant"}],
    request_options={"max_retries": 3},
)
```
The Python SDK supports `request_options` with `max_retries`. [letta](https://www.letta.com/blog/memory-blocks)

### 18. Per-request timeout
```python
folders = client.folders.list(
    request_options={"timeout_in_seconds": 30},
)
```
The docs show `timeout_in_seconds` as a request option. [letta](https://www.letta.com/blog/memory-blocks)

### 19. Extra headers
```python
response = client.blocks.list(
    request_options={
        "additional_headers": {
            "X-Custom-Header": "value"
        }
    }
)
```
Additional headers are a documented advanced configuration option. [letta](https://www.letta.com/blog/memory-blocks)

### 20. Raw response access
```python
response = client.blocks.with_raw_response.list()

print(response.headers)
print(response.data)
```
The SDK docs show `.with_raw_response` access for headers plus parsed data. [letta](https://www.letta.com/blog/memory-blocks)

### 21. Async client
```python
from letta_client import AsyncLetta
import os

async_client = AsyncLetta(api_key=os.environ["LETTA_API_KEY"])

agent = await async_client.agents.create(
    model="openai/gpt-4o-mini",
    embedding="openai/text-embedding-3-small",
    memory_blocks=[
        {"label": "persona", "value": "Helpful assistant"},
    ],
)
```
The Python SDK provides both sync and async clients. [letta](https://www.letta.com/blog/memory-blocks)

## What you should build with SDK only

If your requirement is strictly “I am using python-letta SDK,” then the clean architecture is:
- Use `agents.blocks.retrieve/update` for agent memory editing in UI. [docs.letta](https://docs.letta.com/api/python/resources/agents/subresources/blocks/methods/retrieve/)
- Use `blocks.create/list/retrieve/update/delete` for shared/admin block management. [docs.letta](https://docs.letta.com/api/python/resources/blocks/methods/create/)
- Use `folders/files` APIs for attached documents and searchable file context. [docs.letta](https://docs.letta.com/guides/core-concepts/filesystem/)

So the key clarification is: the Python SDK currently gives you **block CRUD and filesystem/folder/file operations**, but not a documented `MemFS` CRUD namespace similar to Letta Code’s internal git-backed memory filesystem. [docs.letta](https://docs.letta.com/letta-code/memory/)

A compact map of the SDK surfaces:

| Area | SDK surface | What it does |
|---|---|---|
| Agent memory | `client.agents.blocks.retrieve/update`  [docs.letta](https://docs.letta.com/api/python/resources/agents/subresources/blocks/) | Read/update a block attached to one agent |
| Global memory | `client.blocks.create/list/retrieve/update/delete`  [docs.letta](https://docs.letta.com/api/python/resources/blocks/methods/create/) | Manage reusable/shared blocks |
| Attached docs | `client.folders.create/list`, `client.folders.files.upload`  [letta](https://www.letta.com/blog/memory-blocks) | Create searchable file collections |
| Agent file state | `client.agents.folders.attach`, `client.agents.files.open`  [letta](https://www.letta.com/blog/memory-blocks) | Expose folders/files inside an agent context |

Would you like me to give you a **single Python script** that demonstrates all of these SDK operations end-to-end in one place?