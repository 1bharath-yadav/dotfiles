"""Letta SDK functional interface - thin wrapper around letta_client."""

from __future__ import annotations

import os
from typing import Any, Iterator

from letta_client import Letta, AsyncLetta


# ===== CLIENT INITIALIZATION =====

def init_client(api_key: str | None = None, base_url: str | None = None) -> Letta:
    """Initialize Letta synchronous client."""
    key = api_key or os.getenv("LETTA_API_KEY")
    if not key:
        raise ValueError("LETTA_API_KEY not set. Run: export LETTA_API_KEY=sk-...")
    return Letta(api_key=key, base_url=base_url)


def init_async_client(api_key: str | None = None, base_url: str | None = None) -> AsyncLetta:
    """Initialize Letta async client."""
    key = api_key or os.getenv("LETTA_API_KEY")
    if not key:
        raise ValueError("LETTA_API_KEY not set. Run: export LETTA_API_KEY=sk-...")
    return AsyncLetta(api_key=key, base_url=base_url)


# ===== MODELS =====

def get_models(client: Letta) -> Any:
    """GET /api/v1/models"""
    return client.models.list()


# ===== AGENTS =====

def get_agents(client: Letta) -> Any:
    """GET /api/v1/agents"""
    return client.agents.list()


def get_agent(client: Letta, agent_id: str) -> Any:
    """GET /api/v1/agents/{agent_id}"""
    return client.agents.retrieve(agent_id)


def create_agent(
    client: Letta,
    model: str,
    name: str | None = None,
    memory_blocks: list[dict] | None = None,
    tools: list[str] | None = None,
) -> Any:
    """POST /api/v1/agents"""
    kwargs = {"model": model}
    if name:
        kwargs["name"] = name
    if memory_blocks:
        kwargs["memory_blocks"] = memory_blocks
    if tools:
        kwargs["tools"] = tools
    return client.agents.create(**kwargs)


def update_agent(client: Letta, agent_id: str, **kwargs) -> Any:
    """PATCH /api/v1/agents/{agent_id}"""
    return client.agents.update(agent_id, **kwargs)


def delete_agent(client: Letta, agent_id: str) -> Any:
    """DELETE /api/v1/agents/{agent_id}"""
    return client.agents.delete(agent_id)


# ===== MESSAGES (CONVERSATIONS) =====

def resolve_conversation_id(conversation_id: str | None = None) -> str:
    """Return a usable conversation selector for message APIs."""
    return conversation_id or "default"


def send_message(client: Letta, agent_id: str, text: str) -> Any:
    """POST /api/v1/agents/{agent_id}/messages (non-streaming)"""
    return client.agents.messages.create(
        agent_id=agent_id,
        messages=[{"role": "user", "content": text}],
    )


def stream_message(
    client: Letta,
    agent_id: str,
    text: str,
    conversation_id: str | None = None,
    *,
    enable_thinking: str = "true",
    stream_tokens: bool = True,
    include_pings: bool = False,
) -> Iterator[Any]:
    """POST /api/v1/conversations/{conversation_id}/messages (streaming)."""
    return client.conversations.messages.create(
        resolve_conversation_id(conversation_id),
        agent_id=agent_id,
        messages=[{"role": "user", "content": text}],
        enable_thinking=enable_thinking,
        stream_tokens=stream_tokens,
        streaming=True,
        include_pings=include_pings,
    )


def get_messages(
    client: Letta,
    agent_id: str,
    limit: int = 50,
    conversation_id: str | None = None,
) -> Any:
    """GET /api/v1/agents/{agent_id}/messages"""
    kwargs: dict[str, Any] = {"agent_id": agent_id, "limit": limit}
    if conversation_id:
        kwargs["conversation_id"] = conversation_id
    return client.agents.messages.list(**kwargs)


def reset_messages(client: Letta, agent_id: str) -> Any:
    """POST /api/v1/agents/{agent_id}/messages/reset"""
    return client.agents.messages.reset(agent_id=agent_id)


def compact_messages(client: Letta, agent_id: str, method: str = "sliding_window") -> Any:
    """POST /api/v1/agents/{agent_id}/messages/compact"""
    return client.agents.messages.compact(agent_id=agent_id, method=method)


# ===== MEMORY BLOCKS =====

def get_blocks(client: Letta, agent_id: str) -> Any:
    """GET /api/v1/agents/{agent_id}/blocks"""
    return client.agents.blocks.list(agent_id=agent_id)


def get_block(client: Letta, agent_id: str, label: str) -> Any:
    """GET /api/v1/agents/{agent_id}/blocks/{label}"""
    return client.agents.blocks.retrieve(agent_id=agent_id, label=label)


def update_block(client: Letta, agent_id: str, label: str, value: str) -> Any:
    """PATCH /api/v1/agents/{agent_id}/blocks/{label}"""
    return client.agents.blocks.update(agent_id=agent_id, label=label, value=value)


# ===== ARCHIVAL MEMORY (PASSAGES) =====

def get_passages(client: Letta, agent_id: str, limit: int = 20) -> Any:
    """GET /api/v1/agents/{agent_id}/passages"""
    return client.agents.passages.list(agent_id=agent_id, limit=limit)


def search_passages(client: Letta, agent_id: str, query: str, limit: int = 5) -> Any:
    """POST /api/v1/agents/{agent_id}/passages/search"""
    return client.agents.passages.search(agent_id=agent_id, query=query, limit=limit)


# ===== TOOLS =====

def get_tools(client: Letta, agent_id: str) -> Any:
    """GET /api/v1/agents/{agent_id}/tools"""
    return client.agents.tools.list(agent_id=agent_id)


def attach_tool(client: Letta, agent_id: str, tool_id: str) -> Any:
    """POST /api/v1/agents/{agent_id}/tools/attach"""
    return client.agents.tools.attach(agent_id=agent_id, tool_id=tool_id)


def detach_tool(client: Letta, agent_id: str, tool_id: str) -> Any:
    """DELETE /api/v1/agents/{agent_id}/tools/{tool_id}"""
    return client.agents.tools.detach(agent_id=agent_id, tool_id=tool_id)


def get_all_tools(client: Letta) -> Any:
    """GET /api/v1/tools (global tools)"""
    return client.tools.list()


def create_tool(client: Letta, name: str, description: str, definition: dict) -> Any:
    """POST /api/v1/tools"""
    return client.tools.create(name=name, description=description, definition=definition)


# ===== FOLDERS & FILES =====

def get_folders(client: Letta) -> Any:
    """GET /api/v1/folders"""
    return client.folders.list()


def upload_file(client: Letta, folder_id: str, file_path: str) -> Any:
    """POST /api/v1/folders/{folder_id}/files/upload"""
    with open(file_path, "rb") as f:
        return client.folders.files.upload(folder_id=folder_id, file=f)


def get_files(client: Letta, folder_id: str) -> Any:
    """GET /api/v1/folders/{folder_id}/files"""
    return client.folders.files.list(folder_id=folder_id)


# ===== MCP SERVERS =====

def get_mcp_servers(client: Letta) -> Any:
    """GET /api/v1/mcp_servers"""
    return client.mcp_servers.list()


def get_mcp_tools(client: Letta, server_id: str) -> Any:
    """GET /api/v1/mcp_servers/{server_id}/tools"""
    return client.mcp_servers.tools.list(mcp_server_id=server_id)


# ===== TEMPLATES =====

def get_templates(client: Letta) -> Any:
    """GET /api/v1/templates"""
    return client.templates.list()


def create_agent_from_template(client: Letta, template_id: str, name: str | None = None) -> Any:
    """POST /api/v1/templates/{template_id}/agents"""
    kwargs = {}
    if name:
        kwargs["agent_name"] = name
    return client.templates.agents.create(template_id=template_id, **kwargs)


# ===== SECRETS & IDENTITIES =====

def get_secrets(client: Letta) -> Any:
    """GET /api/v1/secrets"""
    return client.secrets.list()


def create_secret(client: Letta, name: str, value: str) -> Any:
    """POST /api/v1/secrets"""
    return client.secrets.create(name=name, value=value)


def delete_secret(client: Letta, secret_id: str) -> Any:
    """DELETE /api/v1/secrets/{secret_id}"""
    return client.secrets.delete(secret_id)


# ===== STREAMING HELPERS =====

def extract_chunk_text(chunk: Any) -> tuple[str, str]:
    """Extract reply and thinking text from stream chunk.
    
    Returns: (reply_token, thinking_token)
    """
    reply_token = ""
    thinking_token = ""
    
    chunk_type = getattr(chunk, "type", None)
    
    if chunk_type == "assistant_message":
        reply_token = getattr(chunk, "content", "")
    elif chunk_type == "reasoning_message":
        thinking_token = getattr(chunk, "reasoning", "")
    
    return (reply_token, thinking_token)


def process_stream(
    stream: Iterator[Any],
    on_thinking: callable = None,
    on_stream_start: callable = None,
    on_token: callable = None,
) -> str:
    """Process streaming response with callbacks.
    
    Args:
        stream: Iterator from stream_message()
        on_thinking: Called with thinking token
        on_stream_start: Called before first reply token
        on_token: Called with each reply token
    
    Returns: Full reply text
    """
    full_reply = ""
    stream_started = False
    
    for chunk in stream:
        reply_token, thinking_token = extract_chunk_text(chunk)
        
        if thinking_token and on_thinking:
            on_thinking(thinking_token)
        
        if reply_token:
            if not stream_started:
                if on_stream_start:
                    on_stream_start()
                stream_started = True
            
            full_reply += reply_token
            if on_token:
                on_token(reply_token)
    
    return full_reply
