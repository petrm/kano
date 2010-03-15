Kano := Object clone do(
  namespaceSeparator  := ":"
  useExternalFile    ::= true
  supportedFiles      := list("Kanofile", "make.io")

  run := method(
    self useExternalFile ifTrue(
      self findKanofiles(Directory with(System launchPath)) foreach(f,
        Namespaces doFile(f path)))

    allArgs := System args exSlice(1) select(exSlice(0, 1) != "-")
    task := allArgs first
    taskArgs := allArgs exSlice(1)
    options := System args select(exSlice(0, 1) == "-")

    options foreach(option,
      option = option exSlice(1)
      if(Namespaces Options hasSlot(option),
        Namespaces Options getSlot(option) call,
        Exception raise("Unknown option: -" .. option)))

    taskParts := task ?split(self namespaceSeparator)
    if(taskParts isNil,
      namespace := "Default"
      taskName  := "_default"
    ,
      namespace := if(taskParts size == 1, "Default", taskParts first)
      taskName  := taskParts last)

    nsName := namespace asMutable makeFirstCharacterUppercase
    ns := Namespaces getSlot(nsName)
    ns isNil ifTrue(
      Exception raise("Unknown namespace: " .. nsName))
    if(ns hasSlot(taskName),
      ns getSlot(taskName) performWithArgList("call", taskArgs),
      Exception raise("Unknown task: " .. taskName)))

  findKanofiles := method(dir,
    dir isNil ifTrue(return(list()))

    files := list(self supportedFiles map(name,
      File with((dir path) .. name)) detect(exists))

    tasksDir := dir directoryNamed("tasks")
    tasksDir exists ifTrue(
      files = files union(tasksDir filesWithExtension("io") map(path)))

    files = files select(!= nil)
    if(files isEmpty, self findKanofiles(dir parentDirectory), files))

  allTasks := method(
    result := Map clone

    Namespaces foreachSlot(nsName, ns,
      ns slotNames sort foreach(slotName,
        ((slotName exSlice(0, 1) != "_") and (ns getLocalSlot(slotName) type == "Block")) ifTrue(
          prettyNsName := if(ns type == "Default",
            "",
            (ns type asMutable makeFirstCharacterLowercase) .. (self namespaceSeparator))
          ns type == "Options" ifTrue(prettyNsName = "-")

          result atPut(prettyNsName .. slotName, ns getLocalSlot(slotName) description))))
    result)
)
