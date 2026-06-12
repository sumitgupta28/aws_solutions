import re

from pydantic import BaseModel, ConfigDict, EmailStr, field_validator

# Loose phone format: optional leading +, then digits/spaces/dashes/parens, 7-20 chars.
_PHONE_RE = re.compile(r"^\+?[0-9\s\-()]{7,20}$")


class CreateUserRequest(BaseModel):
    # Strip surrounding whitespace on all str fields, and reject unknown keys
    # so typos and garbage in the request body surface as a 400.
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    name: str
    email: EmailStr
    phone: str | None = None

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v: str) -> str:
        if not v:
            raise ValueError("name must not be blank")
        return v

    @field_validator("email")
    @classmethod
    def lower_email(cls, v: str) -> str:
        return v.lower()

    @field_validator("phone")
    @classmethod
    def phone_format(cls, v):
        if v and not _PHONE_RE.match(v):
            raise ValueError("phone must be a valid phone number")
        return v


class UpdateUserRequest(CreateUserRequest):
    # All fields optional for PUT; "at least one provided" is enforced in the
    # handler via model_dump(exclude_unset=True). phone is already optional.
    name: str | None = None
    email: EmailStr | None = None

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v):
        if v is not None and not v:
            raise ValueError("name must not be blank")
        return v
