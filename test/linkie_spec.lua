-- DISCLAIMER:
-- This test file contains example URIs for the purpose of testing and demonstration only.
-- Any resemblance to actual, real-world services, hosts, or domains is purely coincidental.
-- The examples are either randomly generated or taken from publicly available sources such as:
-- https://en.wikipedia.org/wiki/List_of_URI_schemes
-- The examples do not represent any actual, functioning resources, nor do they imply any endorsement or affiliation with any real-world service.
-- Use of real domain names or services in these examples is not intended and should not be interpreted as such.

---@diagnostic disable: undefined-global
---@diagnostic disable: unused-local

local Markdown = require 'linkie.markdown'
local Utils = require 'linkie.utils'

-- https://www.rfc-editor.org/rfc/rfc3986.html#section-3.1
describe('URI validation:', function()
    -- file URIs
    it('file URI', function()
        assert.is_true(Utils.validate_uri 'file://host/path')
    end)
    it('file URI with single slash', function()
        assert.is_true(Utils.validate_uri 'file:/path/to/file')
    end)
    it('file URI with windows device letter', function()
        assert.is_true(Utils.validate_uri 'file:///c:/WINDOWS/clock.avi')
    end)
    it('file URI with bar', function()
        assert.is_true(Utils.validate_uri 'file://C|/path/to/file')
    end)
    it('file URI with four slashes', function()
        assert.is_true(Utils.validate_uri 'file:////remotehost/share/dir/file.txt')
    end)

    -- http/https/ftp/irc6/... URIs
    -- https://www.rfc-editor.org/rfc/rfc3986.html
    it('http-like URI', function()
        assert.is_true(Utils.validate_uri 'ftp://ftp.example.com/file.txt')
    end)
    it('http-like URI with user', function()
        assert.is_true(Utils.validate_uri 'http1.0://user@ftp.example.com/file.txt')
    end)
    it('http-like URI with user and password', function()
        assert.is_true(Utils.validate_uri 'https://user:password@ftp.example.com/file.txt')
    end)
    it('http-like URI with port', function()
        assert.is_true(Utils.validate_uri 'irc6://ftp.example.com:21/file.txt')
    end)
    it('http-like URI with user, password, and port', function()
        assert.is_true(Utils.validate_uri 'ftp-ssl://user:password@ftp.example.com:21/file.txt')
    end)
    it('http-like URI with path', function()
        assert.is_true(Utils.validate_uri 'nfs://ftp.example.com/path/to/file.txt')
    end)
    it('http-like URI with user, password, port, and path', function()
        assert.is_true(Utils.validate_uri 'imap://user:password@ftp.example.com:21/path/to/file.txt')
    end)
    it('http-like URI with query and fragment', function()
        assert.is_true(Utils.validate_uri 'foo://example.com:8042/over/there?name=ferret#nose')
    end)
    it('http-like URI with multiple queries', function()
        assert.is_true(Utils.validate_uri 'icap://icap.net/service?mode=translate&lang=french')
    end)
    it('http-like URI with IPv6 address', function()
        assert.is_true(Utils.validate_uri 'http://[2001:db8::1]')
    end)
    it('http-like URI with IPv6 address, port, query and fragment', function()
        assert.is_true(Utils.validate_uri 'http://[2001:db8::1]:8080/index.html?query=test#section-1')
    end)

    -- mailto URIs
    it('mailto URI', function()
        assert.is_true(Utils.validate_uri 'mailto:someone@example.com')
    end)
    it('mailto URI with query', function()
        assert.is_true(Utils.validate_uri 'mailto:someone@example.com?subject=The%20subject&cc=someone_else@example.com&body=The%20body')
    end)
    it('mailto URI with multiple addresses', function()
        assert.is_true(Utils.validate_uri 'mailto:someone@example.com,someoneelse@example.com')
    end)
    it('mailto URI without address', function()
        assert.is_true(Utils.validate_uri 'mailto:?subject=mailto%20with%20examples&body=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FMailto')
    end)

    -- tel URIs
    -- https://www.rfc-editor.org/rfc/rfc3966.html
    it('tel URI', function()
        assert.is_true(Utils.validate_uri 'tel:+1-201-555-0123')
    end)
    it('tel URI with url context', function()
        assert.is_true(Utils.validate_uri 'tel:7042;phone-context=example.com')
    end)
    it('tel URI', function()
        assert.is_true(Utils.validate_uri 'tel:863-1234;phone-context=+1-914-555')
    end)

    -- other URIs
    it('stratum URI with + in scheme', function()
        assert.is_true(Utils.validate_uri 'stratum+udp://server:port')
    end)
    it('geo URI', function()
        assert.is_true(Utils.validate_uri 'geo:25.245470718844146,51.45400942457904')
    end)
    it('urn URI', function()
        assert.is_true(Utils.validate_uri 'urn:uuid:123e4567-e89b-12d3-a456-426614174000')
    end)

    -- invalid URIs
    it('invalid URI (incomplete IPv6 address)', function()
        assert.is_false(Utils.validate_uri 'ftp://[::1234')
    end)
    it('invalid URI (unexpected closing bracket)', function()
        assert.is_false(Utils.validate_uri 'ftp://1234]')
    end)
    it('invalid URI (missing scheme)', function()
        assert.is_false(Utils.validate_uri '://example.com')
    end)
    it('invalid URI (missing path)', function()
        assert.is_false(Utils.validate_uri 'ws://')
    end)
    it('invalid URI (contains space)', function()
        assert.is_false(Utils.validate_uri 'https://example.com/path to/resource')
    end)
    it('invalid URI (absolute unix file path)', function()
        assert.is_false(Utils.validate_uri '/path/to/file.md')
    end)
    it('invalid URI (relative unix file path)', function()
        assert.is_false(Utils.validate_uri './path/to/file.md')
    end)
    it('invalid URI (windows file path)', function()
        assert.is_false(Utils.validate_uri 'C:\\path\\to\\file.txt')
    end)
    it('invalid URI (alternative windows file path)', function()
        assert.is_false(Utils.validate_uri 'C:/Users/user/file.txt')
    end)
    it('invalid URI (markdown section)', function()
        assert.is_false(Utils.validate_uri '#title')
    end)
    it('invalid URI (empty string)', function()
        assert.is_false(Utils.validate_uri '')
    end)
    it('invalid URI (only a colon)', function()
        assert.is_false(Utils.validate_uri ':')
    end)
end)
