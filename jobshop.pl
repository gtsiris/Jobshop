/* Georgios Tsiris, 1115201700173 */

:- set_flag(print_depth,1000).

/* Part 1: jobshop */
jobshop(Schedule) :-
	deadline(Deadline),
	get_machines(Deadline, MachAvs),
	findall(TL, job(_, TL), Tasks),
	timetable(Tasks, 0, MachAvs),
	schedule(MachAvs, Schedule).

get_machines(Deadline, MachAvs) :-
	findall(m(M, N), machine(M, N), L),
	expand(L, Deadline, [], MachAvs).

expand([], _, MachAvs, MachAvs).
expand([m(M, N)|L], Deadline, MachAvs1, MachAvs4) :-
	expand_one(M, N, Deadline, MachAvs2),
	append(MachAvs1, MachAvs2, MachAvs3),
	expand(L, Deadline, MachAvs3, MachAvs4).

expand_one(_, 0, _, []).
expand_one(M, N, Deadline, [m(M, Avs)|MachAvs]) :-
	N > 0,
	N1 is N-1,
	length(Avs, Deadline),
	expand_one(M, N1, Deadline, MachAvs).

timetable([], _, _).
timetable([[Task|[]]|RemainJobs], PrevTaskFinish, MachAvs) :-
	task(Task, Mach, _),
	find_machine(task(Task, Mach, _), _, PrevTaskFinish, MachAvs),
	timetable(RemainJobs, 0, MachAvs).
timetable([[Task|Tasks]|RemainJobs], PrevTaskFinish, MachAvs) :-
	Tasks \= [],
	task(Task, Mach, _),
	find_machine(task(Task, Mach, _), TaskFinish, PrevTaskFinish, MachAvs),
	timetable([Tasks|RemainJobs], TaskFinish, MachAvs).

find_machine(task(Task, Mach, _), TaskFinish, PrevTaskFinish, [m(Mach, MachAv)|_]) :-
	schedule_task(Task, TaskFinish, PrevTaskFinish, MachAv).
find_machine(task(Task, Mach, _), TaskFinish, PrevTaskFinish, [_|MachAvs]) :-
	find_machine(task(Task, Mach, _), TaskFinish, PrevTaskFinish, MachAvs).

schedule_task(Task, TaskFinish, PrevTaskFinish, MachAv) :-
	task(Task, _, Duration),
	extend(Task, Duration, TL),
	sublist(TL, MachAv),
	find_task_start(Task, TaskStart, MachAv),
	TaskStart >= PrevTaskFinish,
	TaskFinish is TaskStart + Duration.

find_task_start(Task, 0, [T|_]) :-
	Task == T,
	!.
find_task_start(Task, TaskStart1, [_|Ts]) :-
	find_task_start(Task, TaskStart2, Ts),
	TaskStart1 is TaskStart2 + 1.

extend(_, 0, []).
extend(T, D, [T|TL]) :-
	D > 0,
	D1 is D - 1,
	extend(T, D1, TL).

sublist(S, L) :-
	append(_, L2, L),
	append(S, _, L2).

schedule([], []).
schedule([m(Mach, MachAv)|MachAvs], Schedule) :-
	schedule(MachAvs, ScheduleTemp),
	setof(Task, (member(Task, MachAv), nonvar(Task)), Tasks),
	format_tasks(Tasks, MachAv, TasksForExec),
	sort_tasks_by_start_time(TasksForExec, [], SortedTasksForExec),
	append([execs(Mach, SortedTasksForExec)], ScheduleTemp, Schedule).

format_tasks([], _, []).
format_tasks([Task|Tasks], MachAv, TasksForExec) :-
	format_tasks(Tasks, MachAv, TasksForExecTemp),
	find_task_start(Task, TaskStart, MachAv),
	task(Task, _, Duration),
	TaskFinish is TaskStart + Duration,
	append([t(Task, TaskStart, TaskFinish)], TasksForExecTemp, TasksForExec).

sort_tasks_by_start_time([], Acc, Acc).
sort_tasks_by_start_time([Task|Tasks], Acc, SortedTasks) :-
	insert_to_sorted_tasks(Task, Acc, NewAcc),
	sort_tasks_by_start_time(Tasks, NewAcc, SortedTasks).

insert_to_sorted_tasks(T1, [], [T1]).
insert_to_sorted_tasks(T1, [T2|Tasks], [T1, T2|Tasks]) :-
	T1 = t(_, Start1, _),
	T2 = t(_, Start2, _),
	Start1 =< Start2.
insert_to_sorted_tasks(T1, [T2|Tasks1], [T2|Tasks2]) :-
	T1 = t(_, Start1, _),
	T2 = t(_, Start2, _),
	Start1 > Start2,
	insert_to_sorted_tasks(T1, Tasks1, Tasks2).

execs(Mach, []) :-
	machine(Mach, _).
execs(Mach, [t(_)|Tasks]) :-
	execs(Mach, Tasks).

t(Task, Start, Finish) :-
	task(Task, _, Duration),
	Finish - Start = Duration.

/* Part 2: jobshop_with_manpower */
t(Task, Start, Finish) :-
	task(Task, _, Duration, _),
	Finish - Start = Duration.

jobshop_with_manpower(Schedule) :-
	deadline(Deadline),
	get_machines(Deadline, MachAvs),
	findall(TL, job(_, TL), Tasks),
	timetable2(Tasks, 0, MachAvs),
	schedule2(MachAvs, Schedule).

timetable2([], _, _).
timetable2([[Task|[]]|RemainJobs], PrevTaskFinish, MachAvs) :-
	task(Task, Mach, _, _),
	find_machine2(task(Task, Mach, _, _), _, PrevTaskFinish, MachAvs, MachAvs),
	timetable2(RemainJobs, 0, MachAvs).
timetable2([[Task|Tasks]|RemainJobs], PrevTaskFinish, MachAvs) :-
	Tasks \= [],
	task(Task, Mach, _, _),
	find_machine2(task(Task, Mach, _, _), TaskFinish, PrevTaskFinish, MachAvs, MachAvs),
	timetable2([Tasks|RemainJobs], TaskFinish, MachAvs).

find_machine2(task(Task, Mach, _, _), TaskFinish, PrevTaskFinish, [m(Mach, MachAv)|_], MachAvs) :-
	schedule_task2(Task, TaskFinish, PrevTaskFinish, MachAv, MachAvs).
find_machine2(task(Task, Mach, _, _), TaskFinish, PrevTaskFinish, [_|MachAvs2], MachAvs) :-
	find_machine2(task(Task, Mach, _, _), TaskFinish, PrevTaskFinish, MachAvs2, MachAvs).

schedule_task2(Task, TaskFinish, PrevTaskFinish, MachAv, MachAvs) :-
	task(Task, _, Duration, _),
	extend(Task, Duration, TL),
	sublist(TL, MachAv),
	find_task_start(Task, TaskStart, MachAv),
	TaskStart >= PrevTaskFinish,
	TaskFinish is TaskStart + Duration,
	get_manpower(MachAvs, Manpower),
	check_manpower(Manpower).

get_manpower([], Manpower) :-
	deadline(Deadline),
	manpower_init(Deadline, Manpower).
get_manpower([m(_, MachAv)|MachAvs], Manpower) :-
	get_manpower(MachAvs, ManpowerAcc),
	get_mach_manpower(MachAv, MachManpower),
	add_element_wise(ManpowerAcc, MachManpower, Manpower).

manpower_init(0, []) :-
	!.
manpower_init(Count, Manpower) :-
	NewCount is Count - 1,
	manpower_init(NewCount, ManpowerAcc),
	append([0], ManpowerAcc, Manpower).

get_mach_manpower([], []).
get_mach_manpower([Task|Tasks], Manpower) :-
	var(Task),
	get_mach_manpower(Tasks, ManpowerAcc),
	append([0], ManpowerAcc, Manpower).
get_mach_manpower([Task|Tasks], Manpower) :-
	nonvar(Task),
	task(Task, _, _, TaskManpower),
	get_mach_manpower(Tasks, ManpowerAcc),
	append([TaskManpower], ManpowerAcc, Manpower).

add_element_wise([], [], []).
add_element_wise([X|Xs], [Y|Ys], SumList) :-
	add_element_wise(Xs, Ys, SumListAcc),
	Z is X + Y,
	append([Z], SumListAcc, SumList).

check_manpower([]).
check_manpower([TaskManpower|Rest]) :-
	check_manpower(Rest),
	staff(Staff),
	TaskManpower =< Staff.

schedule2([], []).
schedule2([m(Mach, MachAv)|MachAvs], Schedule) :-
	schedule2(MachAvs, ScheduleTemp),
	setof(Task, (member(Task, MachAv), nonvar(Task)), Tasks),
	format_tasks2(Tasks, MachAv, TasksForExec),
	sort_tasks_by_start_time(TasksForExec, [], SortedTasksForExec),
	append([execs(Mach, SortedTasksForExec)], ScheduleTemp, Schedule).

format_tasks2([], _, []).
format_tasks2([Task|Tasks], MachAv, TasksForExec) :-
	format_tasks2(Tasks, MachAv, TasksForExecTemp),
	find_task_start(Task, TaskStart, MachAv),
	task(Task, _, Duration, _),
	TaskFinish is TaskStart + Duration,
	append([t(Task, TaskStart, TaskFinish)], TasksForExecTemp, TasksForExec).