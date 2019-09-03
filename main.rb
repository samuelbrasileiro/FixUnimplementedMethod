require_relative 'UnimplementedMethodExtractor.rb'
require_relative 'GitProject.rb'
require_relative 'BCUnimplementedMethod.rb'
require_relative 'FixUnimplementedMethod.rb'

if ARGV.length < 1
  puts "invalid args, valid args example: "
  puts "grumTreePath projectPath"
  puts "projectPath is an optional param"
  return
end

# test = FixUnimplementedMethod.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
# "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
# "attributeCharacteristics")
# test.fix("buildTree", "")

# test = FixUnimplementedMethod.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
#   "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
#   "attributeCharacteristics", 151)
# content = File.read("/home/arthurpires/Documents/faculdade/TAES/fixPatternRequestUpdate/baseCommitClone/src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java")
# test.getMethodName(content, 151)
# return

# Pre setup
puts "Entry your password"
password = STDIN.noecho(&:gets)

gumTree = ARGV[0]

if ARGV.length > 1
  Dir.chdir(ARGV[1])
end
projectPath = Dir.getwd

repLog = `#{"git config --get remote.origin.url"}`
if repLog == ""
  puts "invalid repository"
  return
end

projectName = repLog.split("//")[1]
projectName = projectName.split("github.com/").last.gsub("\n","").gsub(".git", "")
commitHash = `#{"git rev-parse --verify HEAD"}`
commitHash = commitHash.gsub("\n", "")
#print commitHash
print "\n"
# Init  Analysis
gitProject = GitProject.new(projectName, projectPath, "samuelbrasileiro", password)
conflictResult = gitProject.conflictScenario(commitHash) #aqui vamos pegar o parentMerge
#ESTRUTURA CR: [bool, [commits]]
gitProject.deleteProject()

#TIRAR ESSE#if conflictResult[0] #se existir 2 parents
if true
  conflictParents = conflictResult[1] #conflictParents = parentMerge
  #ESTRUTURA [PAI1,PAI2,FILHO]
  travisLog = gitProject.getTravisLog(commitHash)#pegar a log do nosso commit

  unimplementedMethodExtractor = UnimplementedMethodExtractor.new()
  unavailableResult = unimplementedMethodExtractor.extractionFilesInfo(travisLog)
  puts "unavailableResult = \n" << unavailableResult.to_s

  if unavailableResult[0] == "unimplementedMethod"
    conflictCauses = unavailableResult[1]
    ocurrences = unavailableResult[2]
    filePath = unavailableResult[3]
    interfacePath = unavailableResult[4]
    puts filePath
    puts interfacePath
    bcUnimplementedMethod = BCUnimplementedMethod.new(gumTree, projectName, projectPath, commitHash,
      conflictParents, conflictCauses)
    #bcUnSymbolResult = bcUnimplementedMethod.getGumTreeAnalysis()
    #baseCommit = bcUnSymbolResult[1]
    className = conflictCauses[0][1]
    interfaceName = conflictCauses[0][2]
    methodNameByTravis = conflictCauses[0][3]

    puts "A build Conflict was detect, the conflict type is " + unavailableResult[0] + "."
    puts "Do you want fix it? Y or n"
    resp = STDIN.gets()
    # resp = "n"

    puts ">>>>>>>>>>>>>>>Interface to change"
    puts interfacePath
    puts ">>>>>>>>>>>>>>>Conflict Called File"
    puts interfaceName
    puts ">>>>>>>>>>>>>>>Unimplemented Method"
    puts methodNameByTravis
    puts ">>>>>>>>>>>>>>>Class"
    puts className

    if resp != "n" && resp != "N"
      fixer = FixUnimplementedMethod.new(projectName, projectPath, fileToChange, methodNameByTravis)
      fixer.fix(className)
    end
  end
end

puts "FINISHED!"
