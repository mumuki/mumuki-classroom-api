require 'spec_helper'

describe Classroom::Database do
  let!(:initial) { Classroom::Database.current_database }

  describe '.ensure!' do
    before { Classroom::Database.ensure! :foo }

    it { expect(Classroom::Database.current_database).to be initial }
    it { expect(Classroom::Database.with(:foo) { |it| it.client.database_names }).to include 'foo' }
  end

  describe '.with' do
    before { Classroom::Database.with(:bar, &:clean!) }
    before { Classroom::Database.with(:baz, &:clean!) }

    context 'simple usage' do
      before do
        Classroom::Database.with(:bar) do |it|
          @global_set = it == Classroom::Database.current_database
          it.client[:x].insert_one foo: 2
        end
      end

      it { expect(@global_set).to be true }
      it { expect(Classroom::Database.with(:bar) { |it| it.client[:x].count }).to be 1 }
      it { expect(Classroom::Database.current_database).to be initial }
    end

    context 'sequential usage' do
      before { Classroom::Database.with(:bar) { |it| it.client[:x].insert_one foo: 2 } }
      before { Classroom::Database.with(:baz) { |it| it.client[:y].insert_one foo: 2 } }

      it { expect(Classroom::Database.with(:bar) { |it| it.client[:x].count }).to be 1 }
      it { expect(Classroom::Database.with(:baz) { |it| it.client[:x].count }).to be 0 }

      it { expect(Classroom::Database.with(:bar) { |it| it.client[:y].count }).to be 0 }
      it { expect(Classroom::Database.with(:baz) { |it| it.client[:y].count }).to be 1 }
    end

    context 'nested usage' do
      before do
        Classroom::Database.with(:bar) do |bar|
          Classroom::Database.with(:baz) { |baz| baz.client[:y].insert_one foo: 2 }
          bar.client[:x].insert_one foo: 2
        end
      end

      it { expect(Classroom::Database.with(:bar) { |it| it.client[:x].count }).to be 1 }
      it { expect(Classroom::Database.with(:bar) { |it| it.client[:y].count }).to be 0 }

      it { expect(Classroom::Database.with(:baz) { |it| it.client[:x].count }).to be 0 }
      it { expect(Classroom::Database.with(:baz) { |it| it.client[:y].count }).to be 1 }
    end
  end
end
