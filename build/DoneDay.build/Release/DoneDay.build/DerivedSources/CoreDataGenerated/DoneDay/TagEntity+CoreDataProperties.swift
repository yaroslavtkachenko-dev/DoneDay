//
//  TagEntity+CoreDataProperties.swift
//  
//
//  Created by Yaroslav Tkachenko on 01.10.2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias TagEntityCoreDataPropertiesSet = NSSet

extension TagEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
        return NSFetchRequest<TagEntity>(entityName: "TagEntity")
    }

    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isDelete: Bool
    @NSManaged public var name: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for tasks
extension TagEntity {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: TaskEntity)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: TaskEntity)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}

extension TagEntity : Identifiable {

}
