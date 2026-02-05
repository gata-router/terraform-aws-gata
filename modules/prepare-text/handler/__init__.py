"""Prepare text handler package."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2024, 2025, Skwashd Services Pty Ltd https://gata.works"
__license__ = "MIT"

from handler.handler import (
    handler,
    load_text_cleanup_rules,
    prepare_text,
    strip_bad_lines,
)

__all__ = ["handler", "load_text_cleanup_rules", "prepare_text", "strip_bad_lines"]
