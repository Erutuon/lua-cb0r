local cb0r_decode = require "cb0r"
local function cbor_pdecode(...)
    local ok, res, pos = pcall(cb0r_decode, ...)
    if ok then
        return res, pos
    else -- res is error
        return nil, nil, res
    end
end

assert(_VERSION:match "^Lua 5%.[34]$")

local function iter_string(cbor_string)
    local pos = 1
    return function(...)
        if ... then
            return pos
        end
        local val
        val, pos = cb0r_decode(cbor_string, pos)
        return val
    end
end

local function iter_file(path, chunk_size)
    -- variables for testing performance or debugging
    local max_page_cbor_len = 0
    local retries = 0
    local chunk_count = 0
    local total_bytes = 0
    local max_retries = 1000

    assert(math.type(chunk_size) == "integer")
    local file = assert(io.open(path, "rb"))
    local pos = 1
    local on_last_chunk = false
    local chunk

    local function read_chunk()
        local new_chunk = file:read(chunk_size)
        on_last_chunk = #new_chunk < chunk_size
        chunk_count = chunk_count + 1
        total_bytes = total_bytes + #new_chunk
        return new_chunk
    end

    return function(...)
        if ... then
            return "max_page_cbor_len", max_page_cbor_len, "retries", retries, "chunk_count", chunk_count, "total_bytes", total_bytes
        end
        
        if not chunk then
            chunk = read_chunk()
        end
        
        local retry = false
        local current_retries = 0
        local success_count = 0
        
        while true do
            local val, new_pos, error = cbor_pdecode(chunk, pos)
            if val ~= nil and type(val) ~= "table" then
                print(pos, new_pos, #chunk, type(val), error)
            end
            -- Check that new_pos is in range because CBOR library sometimes assigns a ridiculously large number.
            if val and new_pos > pos and new_pos <= #chunk + 1 then
                max_page_cbor_len = math.max(max_page_cbor_len, new_pos - pos)
                pos = new_pos
                success_count = success_count + 1
                return val
            else
                 -- error decoding; read more if there's more to read
                if on_last_chunk then
                    return nil, error
                else
                    chunk = chunk:sub(pos, -1) .. read_chunk()
                    pos = 1
                    if retry then
                        retries = retries + 1
                        current_retries = current_retries + 1
                        if current_retries > max_retries then
                            return nil, "too many retries"
                        end
                    else
                        retry = true
                    end
                end
            end
        end
    end
end

return {
    iter_string = iter_string,
    iter_file = iter_file,
}