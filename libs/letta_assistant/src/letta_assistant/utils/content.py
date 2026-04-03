"""Content normalization utilities for Letta SDK message handling.

Provides type-safe conversion of Letta's Union[str, List[ContentPart]] 
message content to plain text without defensive code patterns.
"""

from __future__ import annotations

from typing import Any, Union

ContentValue = Union[str, list[Any]]


def part_to_text(part: Any) -> str:
    """Convert a single content part to text.
    
    Args:
        part: ContentPart object with 'type' attribute
    
    Returns:
        String representation of the part
    
    Raises:
        TypeError: If part type is unsupported
    """
    t = getattr(part, "type", None)
    
    if t == "text":
        return part.text
    if t == "image":
        return "[image]"
    if t == "tool_call":
        return f"[tool_call:{part.name}]"
    if t == "tool_return":
        return part.content
    if t == "reasoning":
        return part.reasoning
    if t == "redacted_reasoning":
        return "[redacted reasoning]"
    if t == "omitted_reasoning":
        return "[omitted reasoning]"
    if t == "summarized_reasoning":
        return "".join(x.text for x in (part.summary or []))

    # Stream payloads are not always strongly typed content parts.
    for attr in ("text", "content", "reasoning", "message"):
        value = getattr(part, attr, None)
        if isinstance(value, str):
            return value

    if isinstance(part, str):
        return part
    if part is None:
        return ""
    return str(part)


def content_to_text(content: ContentValue) -> str:
    """Convert message content to plain text.
    
    Handles both string and list[ContentPart] union types.
    
    Args:
        content: Union[str, list[ContentPart]]
    
    Returns:
        Plain text string
    """
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, (list, tuple)):
        return "".join(part_to_text(p) for p in content)
    for attr in ("text", "content", "reasoning", "message"):
        value = getattr(content, attr, None)
        if isinstance(value, str):
            return value
    return str(content)


def message_to_text(message: Any) -> str:
    """Extract text from a message object.
    
    Dispatches on message_type to extract content appropriately.
    
    Args:
        message: Message object with message_type attribute
    
    Returns:
        Text content of the message
    
    Raises:
        TypeError: If message type is unsupported
    """
    mt = getattr(message, "message_type", None)
    
    if mt == "assistant_message":
        return content_to_text(message.content)
    if mt == "user_message":
        return content_to_text(message.content)
    if mt == "reasoning_message":
        return message.reasoning
    if mt == "tool_return_message":
        out: list[str] = []
        for tr in (message.tool_returns or []):
            if isinstance(tr.tool_return, str):
                out.append(tr.tool_return)
            else:
                out.append("".join(part_to_text(p) for p in tr.tool_return))
        return "\n".join(out)
    
    raise TypeError(f"Unsupported message type: {mt!r}")
