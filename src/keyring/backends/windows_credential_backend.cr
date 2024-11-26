require "win32cr"
require "../backend"

module Keyring
  class WindowsCredentialBackend < Backend
    # Win32 API Constants
    private CRED_TYPE_GENERIC = 1_u32
    private CRED_PERSIST_LOCAL_MACHINE = 2_u32

    # Win32 API structures and functions
    lib LibCredential
      struct FILETIME
        low_date_time : UInt32
        high_date_time : UInt32
      end

      struct CREDENTIAL_ATTRIBUTE
        keyword : LibC::LPWSTR
        flags : UInt32
        value_size : UInt32
        value : LibC::LPBYTE
      end

      alias PCREDENTIAL_ATTRIBUTE = CREDENTIAL_ATTRIBUTE*

      struct CREDENTIAL
        flags : UInt32
        type : UInt32
        target_name : LibC::LPWSTR
        comment : LibC::LPWSTR
        last_written : FILETIME
        credential_blob_size : UInt32
        credential_blob : LibC::LPBYTE
        persist : UInt32
        attribute_count : UInt32
        attributes : PCREDENTIAL_ATTRIBUTE
        target_alias : LibC::LPWSTR
        username : LibC::LPWSTR
      end

      fun CredWriteW(credential : CREDENTIAL*, flags : UInt32) : Bool
      fun CredReadW(target_name : LibC::LPWSTR, type : UInt32, flags : UInt32, credential : CREDENTIAL**) : Bool
      fun CredDeleteW(target_name : LibC::LPWSTR, type : UInt32, flags : UInt32) : Bool
      fun CredFree(buffer : Void*)
    end

    def set_password(service_name : String, username : String, password : String) : Nil
      target_name = "#{service_name}:#{username}"
      wide_target = UTF16.encode(target_name)
      wide_username = UTF16.encode(username)
      password_bytes = password.encode("UTF-8")

      credential = LibCredential::CREDENTIAL.new
      credential.type = CRED_TYPE_GENERIC
      credential.target_name = wide_target.to_unsafe
      credential.username = wide_username.to_unsafe
      credential.credential_blob = password_bytes.to_unsafe.as(LibC::LPBYTE)
      credential.credential_blob_size = password_bytes.size.to_u32
      credential.persist = CRED_PERSIST_LOCAL_MACHINE

      unless LibCredential.CredWriteW(pointerof(credential), 0)
        error_code = LibC.GetLastError
        raise "Failed to write credential (Error: #{error_code})"
      end
    end

    def get_password(service_name : String, username : String) : String?
      target_name = "#{service_name}:#{username}"
      wide_target = UTF16.encode(target_name)
      cred_ptr = Pointer(LibCredential::CREDENTIAL).null

      if LibCredential.CredReadW(wide_target.to_unsafe, CRED_TYPE_GENERIC, 0, pointerof(cred_ptr))
        begin
          credential = cred_ptr.value
          blob = Slice.new(credential.credential_blob, credential.credential_blob_size)
          return String.new(blob)
        ensure
          LibCredential.CredFree(cred_ptr.as(Void*))
        end
      end
      nil
    end

    def delete_password(service_name : String, username : String) : Nil
      target_name = "#{service_name}:#{username}"
      wide_target = UTF16.encode(target_name)

      unless LibCredential.CredDeleteW(wide_target.to_unsafe, CRED_TYPE_GENERIC, 0)
        error_code = LibC.GetLastError
        raise "Failed to delete credential (Error: #{error_code})"
      end
    end
  end
end
