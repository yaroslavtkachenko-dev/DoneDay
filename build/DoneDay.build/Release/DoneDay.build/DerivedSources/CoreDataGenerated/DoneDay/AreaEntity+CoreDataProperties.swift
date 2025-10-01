//
//  AreaEntity+CoreDataProperties.swift
//  
//
//  Created by Yaroslav Tkachenko on 01.10.2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias AreaEntityCoreDataPropertiesSet = NSSet

extension AreaEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AreaEntity> {
        return NSFetchRequest<AreaEntity>(entityName: "AreaEntity")
    }

    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var iconName: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isDelete: Bool
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var updatedAt: Date?
    @NSManaged public var projects: NSSet?
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for projects
extension AreaEntity {

    @objc(addProjectsObject:)
    @NSManaged public func addToProjects(_ value: ProjectEntity)

    @objc(removeProjectsObject:)
    @NSManaged public func removeFromProjects(_ value: ProjectEntity)

    @objc(addProjects:)
    @NSManaged public func addToProjects(_ values: NSSet)

    @objc(removeProjects:)
    @NSManaged public func removeFromProjects(_ values: NSSet)

}

// MARK: Generated accessors for tasks
extension AreaEntity {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: TaskEntity)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: TaskEntity)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}

extension AreaEntity : Identifiable {

}
