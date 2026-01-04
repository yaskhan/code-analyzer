// Task Management System
// Demonstrates TypeScript interfaces, classes, and methods

/**
 * Task priority levels
 */
enum TaskPriority {
    LOW = "low",
    MEDIUM = "medium", 
    HIGH = "high",
    CRITICAL = "critical"
}

/**
 * Base task interface
 */
interface Task {
    id: number;
    title: string;
    description?: string;
    completed: boolean;
    priority: TaskPriority;
}

/**
 * Task with deadline
 */
interface TaskWithDeadline extends Task {
    deadline: Date;
    estimatedHours: number;
}

/**
 * Task manager class
 */
class TaskManager {
    private tasks: Task[] = [];
    private nextId: number = 1;
    
    /**
     * Creates a new task
     * @param title Task title
     * @param description Optional task description
     * @param priority Task priority level
     * @returns Created task object
     */
    public createTask(title: string, description?: string, priority: TaskPriority = TaskPriority.MEDIUM): Task {
        const task: Task = {
            id: this.nextId++,
            title,
            description,
            completed: false,
            priority
        };
        
        this.tasks.push(task);
        return task;
    }
    
    /**
     * Marks a task as completed
     * @param taskId ID of the task to complete
     * @returns true if task found and marked complete, false otherwise
     */
    public completeTask(taskId: number): boolean {
        const task = this.tasks.find(t => t.id === taskId);
        if (task) {
            task.completed = true;
            return true;
        }
        return false;
    }
    
    /**
     * Gets tasks by priority level
     * @param priority Priority level to filter by
     * @returns Array of tasks with specified priority
     */
    public getTasksByPriority(priority: TaskPriority): Task[] {
        return this.tasks.filter(task => task.priority === priority);
    }
    
    /**
     * Gets all pending tasks
     * @returns Array of incomplete tasks
     */
    public getPendingTasks(): Task[] {
        return this.tasks.filter(task => !task.completed);
    }
    
    /**
     * Gets task statistics
     * @returns Object with task counts
     */
    public getStatistics(): { total: number; completed: number; pending: number } {
        const total = this.tasks.length;
        const completed = this.tasks.filter(task => task.completed).length;
        const pending = total - completed;
        
        return { total, completed, pending };
    }
    
    /**
     * Sorts tasks by priority
     * @returns Array of tasks sorted by priority
     */
    private sortByPriority(): Task[] {
        const priorityOrder = {
            [TaskPriority.CRITICAL]: 1,
            [TaskPriority.HIGH]: 2,
            [TaskPriority.MEDIUM]: 3,
            [TaskPriority.LOW]: 4
        };
        
        return this.tasks.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
    }
}

/**
 * Project task manager that extends basic task management
 */
class ProjectTaskManager extends TaskManager {
    private projectName: string;
    
    constructor(projectName: string) {
        super();
        this.projectName = projectName;
    }
    
    /**
     * Creates a project task with deadline
     * @param title Task title
     * @param deadline Task deadline
     * @param estimatedHours Estimated completion time
     * @param description Task description
     * @returns Task with deadline information
     */
    public createProjectTask(
        title: string, 
        deadline: Date, 
        estimatedHours: number, 
        description?: string
    ): TaskWithDeadline {
        const task = this.createTask(title, description);
        
        return {
            ...task,
            deadline,
            estimatedHours
        };
    }
    
    /**
     * Gets project name
     * @returns Current project name
     */
    public getProjectName(): string {
        return this.projectName;
    }
}