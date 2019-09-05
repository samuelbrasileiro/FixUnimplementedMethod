class FixUnimplementedMethod

  def initialize(projectPath, filePath, unimplementedMethod)
    @projectPath = projectPath
    @filePath = filePath
    @unimplementedMethod = unimplementedMethod
    @initialPath = ""
  end

  def deleteClone()
    Dir.chdir(@initialPath)
    %x(rm -rf baseCommitClone/)
  end


  def fix(abstractName)
    realPath = %x(find . -name "#{abstractName}")
    realPath.sub!(/^\./,"")
    realPath.gsub!(/\n/,"")
    if realPath.match(/#{@filePath}/)
      fileDirectory = Dir.getwd + realPath
      baseFileContent = File.read(fileDirectory)
      array = baseFileContent.split("\n")

      array.each do |line|
        if line.match(/abstract [A-Za-z0-9\_\-]* #{@unimplementedMethod}\(\)/)
          line.sub!(/abstract /, "")
          if line.match(/String/)
            line.sub!(/;/, "{return \"\";};")
          elsif line.match(/(Int|Double|Float)/)
            line.sub!(/;/, "{return 0;};")
          elsif line.match(/Boolean/)
            line.sub!(/;/, "{return false;};")
          else

            line.sub!(/;/, "{return null;};")
          end
        end
      end
      baseFileContent = array.join("\n")
      e = File.open(fileDirectory, 'w')
      e.write(baseFileContent)
      e.close
    end

  end



  def makeCommit()
    Dir.chdir(@projectPath)
    commitMesssage = "Build Conflict resolved automatic, reinsert " << @missingMethod << " declaration in " << @filePath
    %x(git add -u)
    %x(git commit -m "#{commitMesssage}")
  end

end