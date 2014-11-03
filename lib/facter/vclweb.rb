Facter.add(:vclweb) do
  confine :kernel => 'Linux'
  setcode do
    begin
      File.open('/.vclweb', 'r') { | file | 
        file.gets.delete('\n')
      }
    rescue Exception => e
      Puppet.debug e
      Puppet.debug "vclweb not yet set or is corrupt.  Assuming no dojo setup."
      nil
    end
  end
end