class_name ChapterData
extends Resource
## One of Oona's story chapters (decision "After Oona's tasks": written tasks are
## grouped into chapters; the last task of a chapter rewards a rare variety; the
## next chapter opens at a player level). Each chapter is a .tres file in
## scenes/quests/chapters/. A task belongs to a chapter through QuestData.chapter.
## Contents, count and levels are NOT decided — the current files are test data.

## Chapter number (1, 2, 3...). Chapters are played in this order.
@export var number: int = 1
## The player needs at least this level before the chapter's first task is given.
@export var required_level: int = 1
