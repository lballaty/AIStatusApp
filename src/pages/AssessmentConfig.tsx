import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface Category {
  id: string;
  name: string;
  description: string;
  default_value: number;
}

interface AssessmentType {
  id: string;
  name: string;
  description: string;
  categories: Category[];
}

export default function AssessmentConfig() {
  const [assessmentTypes, setAssessmentTypes] = useState<AssessmentType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newAssessmentType, setNewAssessmentType] = useState({ name: '', description: '' });
  const [newCategory, setNewCategory] = useState({
    name: '',
    description: '',
    default_value: 3,
    assessment_type_id: ''
  });

  useEffect(() => {
    fetchAssessmentTypes();
  }, []);

  async function fetchAssessmentTypes() {
    try {
      const { data: types, error: typesError } = await supabase
        .from('assessment_types')
        .select(`
          *,
          categories (*)
        `)
        .order('name');

      if (typesError) throw typesError;
      setAssessmentTypes(types || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function addAssessmentType(e: React.FormEvent) {
    e.preventDefault();
    try {
      const { error } = await supabase
        .from('assessment_types')
        .insert([{
          name: newAssessmentType.name,
          description: newAssessmentType.description
        }]);

      if (error) throw error;
      
      setNewAssessmentType({ name: '', description: '' });
      fetchAssessmentTypes();
    } catch (err: any) {
      setError(err.message);
    }
  }

  async function addCategory(e: React.FormEvent) {
    e.preventDefault();
    try {
      const { error } = await supabase
        .from('categories')
        .insert([{
          name: newCategory.name,
          description: newCategory.description,
          default_value: newCategory.default_value,
          assessment_type_id: newCategory.assessment_type_id
        }]);

      if (error) throw error;
      
      setNewCategory({
        name: '',
        description: '',
        default_value: 3,
        assessment_type_id: ''
      });
      fetchAssessmentTypes();
    } catch (err: any) {
      setError(err.message);
    }
  }

  if (loading) {
    return <div className="p-4">Loading configuration...</div>;
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <h1 className="text-2xl font-bold mb-8">Assessment Configuration</h1>

      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-md mb-4">
          {error}
        </div>
      )}

      {/* Add Assessment Type Form */}
      <div className="bg-white shadow rounded-lg p-6 mb-8">
        <h2 className="text-lg font-medium mb-4">Add New Assessment Type</h2>
        <form onSubmit={addAssessmentType} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Name</label>
            <input
              type="text"
              value={newAssessmentType.name}
              onChange={(e) => setNewAssessmentType(prev => ({ ...prev, name: e.target.value }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Description</label>
            <textarea
              value={newAssessmentType.description}
              onChange={(e) => setNewAssessmentType(prev => ({ ...prev, description: e.target.value }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
          </div>
          <button
            type="submit"
            className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Add Assessment Type
          </button>
        </form>
      </div>

      {/* Add Category Form */}
      <div className="bg-white shadow rounded-lg p-6 mb-8">
        <h2 className="text-lg font-medium mb-4">Add New Category</h2>
        <form onSubmit={addCategory} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Assessment Type</label>
            <select
              value={newCategory.assessment_type_id}
              onChange={(e) => setNewCategory(prev => ({ ...prev, assessment_type_id: e.target.value }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              required
            >
              <option value="">Select Assessment Type</option>
              {assessmentTypes.map(type => (
                <option key={type.id} value={type.id}>{type.name}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Category Name</label>
            <input
              type="text"
              value={newCategory.name}
              onChange={(e) => setNewCategory(prev => ({ ...prev, name: e.target.value }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Description</label>
            <textarea
              value={newCategory.description}
              onChange={(e) => setNewCategory(prev => ({ ...prev, description: e.target.value }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Default Value (1-5)</label>
            <input
              type="number"
              min="1"
              max="5"
              value={newCategory.default_value}
              onChange={(e) => setNewCategory(prev => ({ ...prev, default_value: parseInt(e.target.value) }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              required
            />
          </div>
          <button
            type="submit"
            className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Add Category
          </button>
        </form>
      </div>

      {/* Display Existing Configuration */}
      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-lg font-medium mb-4">Current Configuration</h2>
        <div className="space-y-6">
          {assessmentTypes.map(type => (
            <div key={type.id} className="border-b border-gray-200 pb-4">
              <h3 className="text-lg font-medium text-gray-900">{type.name}</h3>
              <p className="text-gray-500 mb-4">{type.description}</p>
              <h4 className="text-md font-medium mb-2">Categories:</h4>
              <ul className="space-y-2">
                {type.categories?.map(category => (
                  <li key={category.id} className="flex justify-between items-center bg-gray-50 p-3 rounded">
                    <div>
                      <span className="font-medium">{category.name}</span>
                      <p className="text-sm text-gray-500">{category.description}</p>
                    </div>
                    <span className="text-gray-600">Default: {category.default_value}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}