require 'puppet/util/filetype'
Puppet::Type.type(:java_ks).provide(:keytool) do
<<<<<<< HEAD
  desc 'Uses a keytool to manage Java keystores'

  commands :keytool => 'keytool'

  def exists?
    cmd = [
      command(:keytool),
      '-list',
      '-keystore', @resource[:target],
      '-alias', @resource[:name]
    ]
    begin
      tmpfile = Tempfile.new("#{@resource[:name]}.")
      tmpfile.write(@resource[:password])
      tmpfile.flush
      Puppet::Util.execute(
        cmd,
        :stdinfile  => tmpfile.path,
        :failonfail => true,
        :combine    => true
      )
      tmpfile.close!
      return true
    rescue
      return false
    end
  end

  # Reading the fingerprint of the certificate on disk.
  def latest
    cmd = [
      command(:keytool),
      '-printcert','-file', @resource[:certificate]
    ]
    output = Puppet::Util.execute(cmd)
		algo='MD5'
		if @resource[:hash] == :sha1
			algo = 'SHA1'
		end
    latest = output.scan(/#{algo}:\s*([0-9A-F:]*)/)[0][0]
		debug("latest: #{latest}")
    return latest
  end

  # Reading the fingerprint of the certificate currently in the keystore.
  def current
    output = ''
    cmd = [
      command(:keytool),
      '-list',
      '-keystore', @resource[:target],
      '-alias', @resource[:name],
			'-v'
    ]
    tmpfile = Tempfile.new("#{@resource[:name]}.")
    tmpfile.write(@resource[:password])
    tmpfile.flush
    output = Puppet::Util.execute(
      cmd,
      :stdinfile  => tmpfile.path,
      :failonfail => true,
      :combine    => true
    )
    tmpfile.close!
		algo='MD5'
		if @resource[:hash] == :sha1
			algo = 'SHA1'
		end
    current = output.scan(/#{algo}:\s*([0-9A-F:]*)/)[0][0]
		debug("current: #{current}")
    return current
  end

  # Determine if we need to do an import of a private_key and certificate pair
  # or just add a signed certificate, then do it.
  def create
    if ! @resource[:certificate].nil? and ! @resource[:private_key].nil?
     	raise Puppet::Error 'java_ks[provider=>keytool] can not import a private key and certificate without openssl' 
    elsif @resource[:certificate].nil? and ! @resource[:private_key].nil?
      raise Puppet::Error 'Keytool is not capable of importing a private key without an accomapaning certificate.'
    else
      cmd = [
        command(:keytool),
        '-importcert', '-noprompt',
        '-alias', @resource[:name],
        '-file', @resource[:certificate],
        '-keystore', @resource[:target]
      ]
      cmd << '-trustcacerts' if @resource[:trustcacerts] == :true
      tmpfile = Tempfile.new("#{@resource[:name]}.")
      if File.exists?(@resource[:target])
        tmpfile.write(@resource[:password])
      else
        tmpfile.write("#{@resource[:password]}\n#{@resource[:password]}")
      end
      tmpfile.flush
      Puppet::Util.execute(
        cmd,
        :stdinfile  => tmpfile.path,
        :failonfail => true,
        :combine    => true
      )
      tmpfile.close!
    end
  end

  def destroy
    cmd = [
      command(:keytool),
      '-delete',
      '-alias', @resource[:name],
      '-keystore', @resource[:target]
    ]
    tmpfile = Tempfile.new("#{@resource[:name]}.")
    tmpfile.write(@resource[:password])
    tmpfile.flush
    Puppet::Util.execute(
      cmd,
      :stdinfile  => tmpfile.path,
      :failonfail => true,
      :combine    => true
    )
    tmpfile.close!
  end

  # Being safe since I have seen some additions overwrite and some just throw errors.
  def update
    destroy
    create
  end
end
